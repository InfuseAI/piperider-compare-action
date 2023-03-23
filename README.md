# **PipeRider Compare Action 🚀**

The PipeRider Compare Action is a GitHub Action developed by InfuseAI that allows you to run the PipeRider Compare tool directly from your GitHub repository.

## **Description 🔍**

This action runs the PipeRider Compare tool and enables you to compare different versions of your DATA 📊. You can use this action to test the quality of your DATA and identify any kinds of issues. So whether you're a developer 🧑‍💻 or a data scientist 🧑‍🔬, the PipeRider Compare Action can help you ensure that your data is top-notch!

## **Usage**

In order to use the PipeRider Compare Action, you must have a PipeRider project, and create a workflow file in your GitHub repository that specifies this action as one of the steps. It is important to note that this action is only triggered by the pull_request event.

When defining your workflow, you may need to add permissions to the `pull-requests` field in order to enable the action to write to pull requests. You can do this by adding the permissions field as shown below:

To use the PipeRider Compare Action, you can follow the example below:

```yaml
name: PR with PipeRider

on: [pull_request]

jobs:
  piperider-compare:
    runs-on: ubuntu-latest
    permissions:
      pull-requests: write
    steps:
    - uses: actions/checkout@v3

    - name: PipeRider Compare
      uses: InfuseAI/piperider-compare-action@v1
```

It is also possible to use the PipeRider Compare Action with PipeRider Cloud by providing the `cloud_api_token` and `cloud_project` parameters:


```yaml
name: PR with PipeRider

on: [pull_request]

jobs:
  piperider-compare:
    runs-on: ubuntu-latest
    permissions:
      pull-requests: write
    steps:
    - uses: actions/checkout@v3

    - name: PipeRider Compare
      uses: InfuseAI/piperider-compare-action@v1
      with:
        cloud_api_token: ${{ secrets.API_TOKEN }}
        cloud_project: ${{ secrets.PROJECT }}
        upload: true
        share: true
```

Please note that before using the PipeRider Compare Action with PipeRider Cloud, you need to obtain an **`api_token`** and set up the cloud parameters. With the **`upload`** parameter, the action will upload the comparison result to the cloud. The **`share`** parameter is used to generate a shareable link for the comparison result.

We hope these guidelines will help you use the PipeRider Compare Action effectively in your projects.

### **Inputs for PipeRider Compare Action**

The following inputs are available for the PipeRider Compare Action. You can use these inputs to customize the comparison process according to your requirements.

### Basic Parameters

The following basic parameters are available:

| Input | Required | Description |
| --- | --- | --- |
| github_token | No | This input is optional and can be set as GITHUB_TOKEN or as a personal access token with repository access. The default value is ${{ github.token }}. |
| recipe | No | This input is optional and allows you to specify the recipe to use for the comparison. If not specified, the default recipe located at .piperider/compare/default.yml will be used. |

### PipeRider Cloud Parameters

The following parameters are available for using PipeRider Cloud. These parameters only work when the **`cloud_api_token`** has been set.

| Input | Required | Description |
| --- | --- | --- |
| cloud_api_token | No | This input is optional and allows you to specify the API token to use for the PipeRider Cloud API. If not specified, the default API token will be used. |
| cloud_project | No | This input is optional and allows you to specify the cloud project to use for the comparison. If not specified, the default project will be used. |
| upload | No | This input is optional and allows you to specify whether to upload the comparison results to PipeRider Cloud. If set to true, the comparison results will be uploaded. The default value is false. |
| share | No | This input is optional and allows you to specify whether to create a share link for the comparison results. If set to true, a share link will be created. The default value is false. |

We hope this guide will help you use the PipeRider Compare Action more effectively.


### **Outputs**

The action of comparing with PipeRider will upload the report to the artifacts in the GitHub workflow.

## **Support**

If you encounter any issues or have any questions about the PipeRider Compare Action, please **[open an issue](https://github.com/InfuseAI/piperider-compare-action/issues/new)**.