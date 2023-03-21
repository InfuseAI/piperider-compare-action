#!/bin/bash -l
set -o pipefail

if [[ "${GITHUB_EVENT_NAME}" != "pull_request" ]]; then
  echo "This action is designed to work with pull_request events only."
  exit 0
fi

export GITHUB_ACTION_URL="https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"

piperider version && rm .piperider/.unsend_events.json

uuid=$(uuidgen -n @oid -N "${GITHUB_REPOSITORY}" --sha1 | tr -d "-")
sed -i "s/^user_id: .*$/user_id: ${uuid}/" ~/.piperider/profile.yml

if [ -f ${GITHUB_WORKSPACE}/requirements.txt ]; then
    pip install --no-cache-dir -r ${GITHUB_WORKSPACE}/requirements.txt
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

echo "::set-output name=status::${rc}"
echo "::set-output name=uuid::${uuid}"

# TODO enable it after compare working
# pushd /usr/src/github-action
# /root/.nvm/versions/node/v16.13.0/bin/node index.js $rc || exit $?
# popd
