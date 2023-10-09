# Use Pulumi in CI/CD Pipelines with GitHub Actions

## Prerequisites

- Pulumi account
- Azure Subscription
- Azure CLI
- GitHub CLI

The GitHub CLI can be installed on Windows using the following command:

```powershell
winget install -e --id GitHub.cli
```

You should have completed the `Getting Started Provisionning Infrastructure on Azure with Pulumi` tutorial before doing this tutorial

> [!NOTE]  
> If you have not completed the previous tutorial, you can just create a new directory and create a new Azure Pulumi project in an `infra` subdirectory using the command `pulumi new azure-csharp`.

## Initialize a new GitHub repository

- In you current directory, create a `.github\workflows` folder.
- Copy the `infra.yml` workflow file (located alongside these instructions) in this `.github\workflows` folder.

The workflow file run the pulumi action with the `pulumi up` command on the `dev` stack. If you are using .NET or Go, dependencies will be automatically restored when running the `pulumi up` command, so you don't need to add a step before to restore the dependencies. Otherwhise (for Python or Node.js runtimes for instance) you should modify the file to add one.

- Initialize the git repository with your Pulumi project and the workflow file

```pwsh
git init
git add .
git commit -m "Intialize repository with infrastructure code"
```

- Create a new remote private GitHub repository

```pwsh
gh repo create pulumi-azure-workshop-lab --private --source=. --push

# Retrieve the repository full name (org/repo)
$repositoryFullName=$(gh repo view --json nameWithOwner -q ".nameWithOwner")
```

## Create the identity in Microsoft Entra ID for the GitHub Actions workflow

Execute the different steps of this script to configure an Azure App Registration in Microsoft Entra Id. GitHub Actions will be allowed to autenticate to Azure from the main branch of this GitHub repository.

```pwsh
# Retrieve the current subscription and current tenant identifiers 
$subscriptionId=$(az account show --query "id" -o tsv)
$tenantId=$(az account show --query "tenantId" -o tsv)

# Create an App Registration and its associated service principal
$appId=$(az ad app create --display-name "GitHub Action OIDC for Pulumi Workshop" --query "appId" -o tsv)
$servicePrincipalId=$(az ad sp create --id $appId --query "id" -o tsv)

# Assign the contributor role to the service principal on the subscription
az role assignment create --role contributor --subscription $subscriptionId --assignee-object-id  $servicePrincipalId --assignee-principal-type ServicePrincipal --scope /subscriptions/$subscriptionId

# Prepare parameters for federated credentials
$parametersJson = @{
    name = "FederatedIdentityForWorkshop"
    issuer = "https://token.actions.githubusercontent.com"
    subject = "repo:${repositoryFullName}:ref:refs/heads/main"
    description = "Deployments for Pulumi workshop"
    audiences = @(
        "api://AzureADTokenExchange"
    )
}

# Change parameters to single line string with escaped quotes to make it work with Azure CLI
# https://medium.com/medialesson/use-dynamic-json-strings-with-azure-cli-commands-in-powershell-b191eccc8e9b
$parameters = $($parametersJson | ConvertTo-Json -Depth 100 -Compress).Replace("`"", "\`"")

# Create federated credentials
az ad app federated-credential create --id $appId --parameters $parameters
```

> [!NOTE]  
> Instead of relying on OIDC/Workload identity federation to authenticate to Azure, you could use a client secret from the service principal you created but that's not the best practice because it involves a secret that has to be secured and regularly rotated. 

## Add the configuration for the GitHub Actions workflow

- Add the GitHub secrets for the federated identity that will be used by the GitHub Actions workflow

```pwsh
gh secret set ARM_TENANT_ID --body $tenantId
gh secret set ARM_SUBSCRIPTION_ID --body $subscriptionId
gh secret set ARM_CLIENT_ID --body $appId
```

- Create a Pulumi [access token](https://www.pulumi.com/docs/pulumi-cloud/access-management/access-tokens/) from your Pulumi account 

```pwsh
$pulumiToken = "pul-******************"
gh secret set PULUMI_ACCESS_TOKEN --body $pulumiToken
```

## Run the workflow to provision Azure resources

- Run the infra workflow and watch its progress

```pwsh
gh workflow run infra.yml
$runId=$(gh run list --workflow=infra.yml --json databaseId -q ".[0].databaseId")
gh run watch $runId
```

- Open the GitHub repository in the browser

```pwsh
gh repo view -w
```

- Check the Azure resources have been created in the azure portal

> [!NOTE]  
> Instead of using scripts to create and configure the github repository and the workfload identity federation, we could also have used Pulumi like explained in this [article](https://www.techwatching.dev/posts/azure-ready-github-repository)