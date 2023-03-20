#!/bin/bash -l
set -o pipefail

export GITHUB_ACTION_URL="https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"

piperider version && rm .piperider/.unsend_events.json

uuid=$(uuidgen -n @oid -N "${GITHUB_REPOSITORY}" --sha1 | tr -d "-")
sed -i "s/^user_id: .*$/user_id: ${uuid}/" ~/.piperider/profile.yml

if [ -f ${GITHUB_WORKSPACE}/requirements.txt ]; then
    pip install --no-cache-dir -r ${GITHUB_WORKSPACE}/requirements.txt
fi


# required by running compare with the GitHub action
git config --global --add safe.directory /github/workspace
echo "branch --"
git branch 
echo "status --"
git status
echo "go compare --"

piperider compare ; rc=$?

echo "::set-output name=status::${rc}"
echo "::set-output name=uuid::${uuid}"

# TODO enable it after compare working
# pushd /usr/src/github-action
# /root/.nvm/versions/node/v16.13.0/bin/node index.js $rc || exit $?
# popd
