const fs = require('fs');
const path = require('path');
const core = require('@actions/core');
const artifact = require('@actions/artifact');
const github = require('@actions/github');

const context = github.context;
const { exit } = require('process');

const {GITHUB_TOKEN} = process.env;
const {GITHUB_EVENT_PATH} = process.env;
const {GITHUB_WORKSPACE} = process.env;
const {GITHUB_ACTION_URL} = process.env;

function isFileExists(path) {
  try {
    fs.accessSync(path, fs.constants.F_OK);
    return true;
  } catch (e) {
    return false;
  }
}

function getPipeRiderOutputLog() {
  const outputLog = `${GITHUB_WORKSPACE}/output.log`;
  if (isFileExists(outputLog)) {
    return fs.readFileSync(outputLog, 'utf8');
  }
  return '';
}

function getSummarySection(outputLog) {
  var lines = outputLog.split('\n');
  var summarySection = false;
  var summary = [];
  for (var i = 0; i < lines.length; i++) {
    if (/─+ Summary ─+/.test(lines[i])) {
      summarySection = true;
    }

    if (lines[i].indexOf('Generating reports from') > -1) {
      break;
    }

    if (summarySection) {
      summary.push(lines[i]);
    }
  }
  return summary.join('\n');
}

function generateGitHubPullRequestComment(returnCode) {
  const colorCodeRegex = /[\u001b\u009b][[()#;?]*(?:[0-9]{1,4}(?:;[0-9]{0,4})*)?[0-9A-ORZcf-nqry=><]/g;
  const outputLog = getPipeRiderOutputLog().replace(colorCodeRegex, '');
  const summary = getSummarySection(outputLog);
  const status = (returnCode === '0') ? '✅ Success' : '❌ Failure';
  return `
# PipeRider CLI Report
> Test Result: ${status}
> Test Report: ${GITHUB_ACTION_URL}
\`\`\`
${summary}
\`\`\`
<details>
<summary>Click to see detail PipeRider assessment</summary>

\`\`\`
${outputLog}
\`\`\`
</details>
`;
}

function getFilesUnderDir(dir) {
  var results = [];
  var list = fs.readdirSync(dir);
  list.forEach(function(file) {
      file = path.join(dir, file);
      var stat = fs.statSync(file);
      if (stat && stat.isDirectory()) {
          /* Recurse into a subdirectory */
          results = results.concat(getFilesUnderDir(file));
      } else {
          /* Is a file */
          results.push(file);
      }
  });
  return results;
}

function getReportArtifacts(dir) {
  var results = [];
  var list = fs.readdirSync(dir);

  list.forEach(function(file) {
      file = path.join(dir, file);
      var stat = fs.statSync(file);
      if (stat && stat.isFile() && !file.endsWith('.json')) {
        results.push(file);
      } else if (stat && stat.isDirectory()) {
        // add files for html rendering usage
        results = results.concat(getFilesUnderDir(file));
      }
  });

  return results;
}

async function run (argv) {
  const returnCode = argv[0] || '0';
  const octokit = github.getOctokit(GITHUB_TOKEN);
  const event = (isFileExists(GITHUB_EVENT_PATH)) ? require(GITHUB_EVENT_PATH) : null;

  core.debug(`PipeRider return code: ${returnCode}`);
  if (event === null) {
    core.warning('GitHub Action is not triggered by event');
    return;
  }

  if (event.pull_request) {
    // Action triggered by pull request
    core.debug(`GitHub Action triggered by pull request #${event.pull_request.number}`);
    const prNumber = event.pull_request.number;
    await octokit.rest.issues.createComment({
      ...context.repo,
      issue_number: prNumber,
      body: generateGitHubPullRequestComment(returnCode)
    });
  }

  exit(returnCode);
}

const argv = process.argv.slice(2);
run(argv);