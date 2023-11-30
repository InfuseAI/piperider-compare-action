#!/bin/bash -l
set -o pipefail

if [[ "${GITHUB_EVENT_NAME}" != "pull_request" ]]; then
  echo "[Error] This action is designed to work with pull_request events only."
  echo "::error::This action is designed to work with pull_request events only."
  exit 0
fi

export GITHUB_ACTION_URL="https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
if [[ "${INPUT_PIPERIDER_VERSION:-}" != "" ]]; then
  echo "[PipeRider] Installing piperider==${INPUT_PIPERIDER_VERSION}"
  
  pip install -q --no-cache-dir piperider==${INPUT_PIPERIDER_VERSION} || echo "[PipeRider] Failed to install piperider==${INPUT_PIPERIDER_VERSION}"
fi

echo "[PipeRider] Version: $(piperider version && rm .piperider/.unsend_events.json)"

# Replace the user_id with a unique id for the repository
uuid=$(uuidgen -n @oid -N "${GITHUB_REPOSITORY}" --sha1 | tr -d "-")
sed -i "s/^user_id: .*$/user_id: ${uuid}/" ~/.piperider/profile.yml
if [[ "${INPUT_WORKING_DIRECTORY:-}" != "" ]]; then
    export PIPERIDER_WORKSPACE=$(realpath ${INPUT_WORKING_DIRECTORY})
else
    export PIPERIDER_WORKSPACE=${GITHUB_WORKSPACE}
fi

# Install the requirements if the file exists in the repository
if [ -f ${PIPERIDER_WORKSPACE}/requirements.txt ]; then
    echo "[PipeRider] Installing requirements.txt"
    pip install -q --no-cache-dir -r ${PIPERIDER_WORKSPACE}/requirements.txt
fi

# Install the piperider data connectors based on .piperider/config.yml
for datasource_type in $(yq '.dataSources[].type' ${PIPERIDER_WORKSPACE}/.piperider/config.yml); do
    case "${datasource_type}" in
        sqlite)
            echo "[PipeRider] Skipping sqlite, it is built-in"
        ;;
        *)
            pip install -q --no-cache-dir piperider[${datasource_type}] || echo "[PipeRider] Failed to install piperider[${datasource_type}]"; true
            # Patch oscrypto manually before the next release
            # Ref: https://github.com/wbond/oscrypto/issues/75
            if [ "${datasource_type}" == "snowflake" ]; then
                oscrypto_version=`pip list | grep oscrypto | awk '{print $2}' 2> /dev/null`
                if [ "$oscrypto_version" == "1.3.0" ]; then
                    echo "[Patch] oscrypto with latest OpenSSL"
                    pip uninstall oscrypto -y
                    pip install oscrypto@git+https://github.com/wbond/oscrypto.git@d5f3437ed24257895ae1edd9e503cfb352e635a8
                fi
            fi
        ;;
    esac
done

# Setup credentials for the data connectors if user provides
if [ "${INPUT_CREDENTIALS_YML:-}" != '' ]; then
    echo "[PipeRider] Setting up credentials.yml"
    echo "${INPUT_CREDENTIALS_YML}" > ${PIPERIDER_WORKSPACE}/.piperider/credentials.yml
fi

# work around for dev helper
# pip install -q git+https://github.com/InfuseAI/piperider.git@feature/sc-30601/make-compare-recipe-working-on-github-action -t /tmp/utils


# required by running compare with the GitHub action
git config --global --add safe.directory /github/workspace

# make the git merge-base working
git fetch --unshallow

set -e
echo "[PipeRider] Running piperider compare"
echo "Working directory: ${PIPERIDER_WORKSPACE}"
pushd ${PIPERIDER_WORKSPACE} > /dev/null
# invoke the github-action helper script
python -m piperider_cli.recipes.github_action prepare_for_action
run_commands=$(python -m piperider_cli.recipes.github_action make_recipe_command)
IFS=$'\n'
for cmd in $run_commands; do
    echo "[PipeRider] CMD Execute => $cmd"
    eval $cmd ; rc=$?
done

echo "status=${rc}" >> $GITHUB_OUTPUT
echo "uuid=${uuid}" >> $GITHUB_OUTPUT
cat ./summary.md >> $GITHUB_STEP_SUMMARY

python -m piperider_cli.recipes.github_action attach_comment
popd > /dev/null
