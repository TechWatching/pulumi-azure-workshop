param (
    [Parameter(Mandatory=$true)]
    [string]$PulumiToken
)

# Retrieve the repository full name (org/repo)
$repositoryFullName=$(gh repo view --json nameWithOwner -q ".nameWithOwner")

# Retrieve the current subscription and current tenant identifiers 
$subscriptionId=$(az account show --query "id" -o tsv)
$tenantId=$(az account show --query "tenantId" -o tsv)

# Create an App Registration and its associated service principal
$appId=$(az ad app create --display-name "GitHub Action OIDC for ${repositoryFullName}" --query "appId" -o tsv)
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

# Create GitHub secrets needed for the GitHub Actions
gh secret set ARM_TENANT_ID --body $tenantId
gh secret set ARM_SUBSCRIPTION_ID --body $subscriptionId
gh secret set ARM_CLIENT_ID --body $appId
gh secret set PULUMI_ACCESS_TOKEN --body $PulumiToken