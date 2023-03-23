#!/bin/bash -l
set -o pipefail

if [[ "${GITHUB_EVENT_NAME}" != "pull_request" ]]; then
  echo "This action is designed to work with pull_request events only."
  exit 0
fi

export GITHUB_ACTION_URL="https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"

piperider version && rm .piperider/.unsend_events.json

# Replace the user_id with a unique id for the repository
uuid=$(uuidgen -n @oid -N "${GITHUB_REPOSITORY}" --sha1 | tr -d "-")
sed -i "s/^user_id: .*$/user_id: ${uuid}/" ~/.piperider/profile.yml

# Install the requirements if the file exists in the repository
if [ -f ${GITHUB_WORKSPACE}/requirements.txt ]; then
    pip install --no-cache-dir -r ${GITHUB_WORKSPACE}/requirements.txt
fi

# Install the piperider data connectors based on .piperider/config.yml
for datasource_type in "$(yq '.dataSources[].type' ${GITHUB_WORKSPACE}/.piperider/config.yml)"; do
    case "${datasource_type}" in
        sqlite)
            echo "Already includes sqlite"
        ;;
        *)
            pip install --no-cache-dir piperider[${datasource_type}] || echo "Failed to install piperider[${datasource_type}]"; true
        ;;
    esac
done

# Setup credentials for the data connectors if user provides
if [ "${INPUT_CREDENTIALS_YML:-}" != '' ]; then
    echo "Setting up credentials.yml"
    echo "${INPUT_CREDENTIALS_YML}" > ${GITHUB_WORKSPACE}/.piperider/credentials.yml
fi

# work around for dev helper
pip install git+https://github.com/InfuseAI/piperider.git@feature/sc-30601/make-compare-recipe-working-on-github-action -t /tmp/utils


# required by running compare with the GitHub action
git config --global --add safe.directory /github/workspace

# make the git merge-base working
git fetch --unshallow

set -e
# invoke the github-action helper script
PYTHONPATH=/tmp/utils python -m piperider_cli.recipes.github_action prepare_for_action
run_command=$(PYTHONPATH=/tmp/utils python -m piperider_cli.recipes.github_action make_recipe_command)
echo "will execute => $run_command"

eval $run_command ; rc=$?

echo "status=${rc}" >> $GITHUB_OUTPUT
echo "uuid=${uuid}" >> $GITHUB_OUTPUT
echo "uuid=${uuid}" >> $GITHUB_STEP_SUMMARY

PYTHONPATH=/tmp/utils python -m piperider_cli.recipes.github_action attach_comment