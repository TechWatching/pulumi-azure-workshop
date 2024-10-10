# Use Pulumi in CI/CD Pipelines with GitHub Actions

## Prerequisites

- Pulumi account
- Azure Subscription
- Azure CLI
- GitHub CLI

Follow the instructions on [this page](https://github.com/cli/cli#installation) to install the GitHub CLI.

On Windows, you can install the GitHub CLI using PowerShell and Windows Package Manager like this:

```powershell
winget install -e --id GitHub.cli
```

You should have completed the [Getting Started Provisionning Infrastructure on Azure with Pulumi](./README.md) tutorial before doing this tutorial

> [!NOTE]  
> If you have not completed the previous tutorial, you can just create a new directory and create a new Azure Pulumi project in an `infra` subdirectory using the command `pulumi new azure-csharp`.

## Initialize a new GitHub repository

- Go in the root directory for this workshop (it should be the parent of the `infra` folder), all future shell commands should be executed from this folder. 
- Create a `.github\workflows` folder.
- Copy the `infra.yml` workflow file (located alongside these instructions) in this `.github\workflows` folder.

The workflow file contains the pipeline to provision the infrastructure defined in the infra folder. It uses the [Pulumi GitHub Actions](https://github.com/pulumi/actions) that will execute the `pulumi up` command on the `dev` stack. Have a look at the `infra.yml` file to understand what it's doing.

> [!NOTE]
> The `Pulumi GitHub Actions` is configured in the file to work with Pulumi Cloud. If you are not using Pulumi Cloud as your backend and encryption provider, you will have to make some adjustments to the configuration, you can check these [examples](https://github.com/pulumi/actions/tree/main/examples).

If you are using .NET or Go, dependencies will be automatically restored when running the `pulumi up` command in the pipeline, so you don't need to add a step before to restore the dependencies. You may do it anyway to specify a version of .NET or Go to use. Otherwise (for Python or Node.js runtimes for instance) you should modify the `infra.yml` workflow file to restore the dependencies.

<details>
  <summary>Steps to add for TypeScript</summary>

```yaml
- name: Install pnpm
  uses: pnpm/action-setup@v4
  with:
    version: latest

- name: Use Node.js LTS version
  uses: actions/setup-node@v4
  with:
    node-version: 'lts/*'
    cache: 'pnpm'
    cache-dependency-path: './infra/pnpm-lock.yaml'

- name: Install dependencies
  run: pnpm install
  working-directory: 'infra'
```
</details>

- Initialize the git repository with your Pulumi project and the workflow file

```powershell
git init
git add .
git commit -m "Initialize repository with infrastructure code"
```

- Create a new remote private GitHub repository

```powershell
gh repo create pulumi-azure-workshop-lab --private --source=. --push
```

## Create the identity in Microsoft Entra ID for the GitHub Actions workflow and register the configuration in the GitHub Secrets 

- Create a Pulumi [access token](https://www.pulumi.com/docs/pulumi-cloud/access-management/access-tokens/) from your Pulumi account to be able to interact with the Pulumi Cloud backend of your project from the pipeline.

> [!NOTE]
> You could also use OpenID Connect to authenticate to your Pulumi account instead of relying on a personal access token. You can check [this article](https://www.pulumi.com/docs/pulumi-cloud/access-management/oidc/client/github/) to see how to do that.

- Copy the `configureAzureWorkloadIdentity.ps1` or the `configureAzureWorkloadIdentity.sh`script (depending on your preference) in your repository folder.

- Replace 'pul-********' by your access token, and execute the `configureAzureWorkloadIdentity` script that will configure everything needed for the pipeline to provision the infrastructure in Azure:

<details open>
  <summary>Command in PowerShell</summary>

```powershell
.\configureAzureWorkloadIdentity.ps1 -PulumiToken 'pul-********'
```
</details>

<details open>
  <summary>Command in Bash</summary>

(first, make the script executable by running `chmod +x configureAzureWorkloadIdentity.sh`) 
```bash
./configureAzureWorkloadIdentity.sh --PulumiToken='pul-********'
```
</details>

> [!NOTE]
> The script configures an Azure App Registration and its federated identity credentials in Microsoft Entra Id. That will allow the GitHub Actions workflow to authenticate to Azure from the main branch of this GitHub repository. The script will also register the GitHub Secrets for the federated identity that will be used by the GitHub Actions workflow. Because this does not rely on a service principal secret, it's a more secure way of authenticating to Azure from a CI/CD pipeline. Check the [documentation](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation#how-it-works) if you want to better understand how Workload Identity Federation works.

## Run the workflow to provision Azure resources

- Run the infra workflow

```powershell
gh workflow run infra.yml
```

- Watch the workflow progress

<details open>
  <summary>Command in PowerShell</summary>

```powershell
$runId=$(gh run list --workflow=infra.yml --json databaseId -q ".[0].databaseId");
gh run watch $runId;
```

</details>

<details open>
  <summary>Command in Bash</summary>

```bash
runId=$(gh run list --workflow=infra.yml --json databaseId -q ".[0].databaseId");
gh run watch $runId;
```

</details>


- Open the GitHub repository in the browser

```powershell
gh repo view -w
```

- Check the Azure resources have been created in the azure portal

> [!NOTE]  
> Instead of using scripts to create and configure the GitHub repository and the workload identity federation, we could also have used Pulumi like explained in this [article](https://www.techwatching.dev/posts/azure-ready-github-repository)

## Use stack outputs

- Check the [Pulumi GitHub Actions](https://github.com/pulumi/actions) documentation and add a step in the workflow to echo the `appServiceUrl` stack output.

<details>
  <summary>GitHub Actions workflow</summary>

```yaml
- name: Provision infrastructure
  uses: pulumi/actions@v6
  id: pulumi
  with:
    command: up
    stack-name: dev
    work-dir: infra
  env:
    PULUMI_ACCESS_TOKEN: ${{ secrets.PULUMI_ACCESS_TOKEN }}

- run: echo "App service url is ${{ steps.pulumi.outputs.appServiceUrl }}"
```

</details>