# Getting Started Provisioning Infrastructure on Azure with Pulumi

## Prerequisites

### Installations & configurations

- Azure Subscription
- Azure CLI
- Pulumi CLI
- Your preferred language runtime
- Your favorite IDE

This [page](https://www.pulumi.com/docs/clouds/azure/get-started/begin/) in the documentation covers all you need to do to set up your environment.

> [!NOTE]  
> You can use the OS, language, and IDE you want for this workshop. Yet for the sake of simplicity, the samples in the tutorial won't cover every possible configuration. That should not prevent you from choosing the technologies and tools you are already familiar with to complete this workshop.

On Windows for instance, you can set up you environment using PowerShell and Windows Package Manager like this:

```powershell
# Install Azure CLI using winget
winget install -e --id Microsoft.AzureCLI

# Install Pulumi CLI using winget
winget install -e --id=Pulumi.Pulumi

# Log in to Azure
# You can specify the -t option with your tenant identifier if you have multiple tenants
az login

# (Optional) List your available subscriptions and grab the identifier of the subscription you want to use
az account list --query "[].{id:id, name:name}"

# (Optional) Set the correct subscription identifier, "79400867-f366-4ec9-84ba-d1dca756beb5 in the example below
az account set -s 79400867-f366-4ec9-84ba-d1dca756beb5
az account show

# (Optional) Install the .NET SDK
winget install Microsoft.DotNet.SDK.8
```

### Choose a backend

As Pulumi is a declarative IaC solution that uses a state to manage the cloud resources, a place to store this state is needed: the "backend". An encryption provider is also needed to encrypt that will be used. You can check this [article in the documentation](https://www.pulumi.com/docs/concepts/state/#managing-state-backend-options) to see the different backends and encryption providers available. 

The most convenient way of doing this workshop without worrying about configuring a backend or an encryption provider is to use Pulumi Cloud which is free for individuals. You can just create an account [here](https://app.pulumi.com/signup) (or sign in using your GitHub/GitLab account) and that's it.

If you don't want to use Pulumi Cloud, that's totally fine too, check the documentation or this [article](https://www.techwatching.dev/posts/pulumi-azure-backend) that demonstrates how to use Pulumi with Azure Blob Storage as the backend  and Azure Key Vault as the encryption provider (script to configure these resources is available at the end of the article).

Log in to your backend using the [pulumi login CLI command](https://www.pulumi.com/docs/iac/cli/commands/pulumi_login/)

<details open>
  <summary>Log in to Pulumi Cloud</summary>

```powershell
pulumi login
```
</details>

## Pulumi fundamentals

### Create a basic Pulumi project

1. Create a new directory for the workshop with a new `infra` directory in it.
```powershell
mkdir pulumi-workshop; cd pulumi-workshop; mkdir infra; cd infra
```

2. List the available templates
```powershell
pulumi new -l
```

There are several azure templates (prefixed by azure) that are already configured to provision resources to Azure, but for the purpose of this workshop you will start a project from scratch to better understand how everything works.

3. Create a new Pulumi project using an empty template (corresponding to the language of your choice)

```powershell
pulumi new typescript -n PulumiAzureWorkshop -s dev -d "Workshop to learn Pulumi with Azure fundamentals"
```

The `-s dev` option is used to initialize the project with a stack named `dev`. A [stack](https://www.pulumi.com/docs/concepts/stack/#stacks) is an independently configurable instance of a Pulumi program. Stacks are mainly use to have a different instance for each environment (dev, staging, preprod, prod ...). or for [each developer making changes to the infrastructure](https://www.pulumi.com/blog/iac-recommended-practices-developer-stacks-git-branches/#using-developer-stacks).

> [!NOTE]  
> If you forget to log in before, you will be prompted to log in to Pulumi Cloud when running this command. Just use your GitHub/GitLab account or the credentials of the account you previously created. If you use a self-hosted backend, log in with the appropriate backend url before running the `pulumi new` command.

Open the project in your favorite IDE to browse the files.

### Deploy a stack

Use [`pulumi up`](https://www.pulumi.com/docs/cli/commands/pulumi_up/) to deploy the stack

The command will first display a preview of the changes and then ask you whether you want to apply the changes. Select yes.

As there are currently no resources in the Pulumi program, only the stack itself will be created in the state, no cloud resources will be provisioned.

Depending on your template, the Pulumi program may contain an output that is displayed once the command is executed. [Outputs](https://www.pulumi.com/docs/iac/concepts/stacks/#outputs) can be used to retrieve information from a Pulumi stack like URL from provisioned cloud resources.

- If there is not existing output, add an output `outputKey` with a value `outputValue`.

<details>
  <summary>Code in C#</summary>

```csharp
return new Dictionary<string, object?>
{
   ["outputKey"] = "outputValue"
};
```
</details>

<details>
  <summary>Code in TypeScript</summary>

```typescript
export const outputKey = "outputValue"
```
</details>

<details>
  <summary>Code in Python</summary>

```typescript
pulumi.export("outputKey", "outputValue")
```
</details>

### Handle stack configuration, stack outputs, and secrets

[Configuration](https://www.pulumi.com/docs/concepts/config/) allows you to configure resources with different settings depending on the stack you are using. A basic use case is to have the pricing tier of a resource in the configuration to have less expensive/powerful machines in the development environment than in production.

1. Add a setting named `AppServiceSku` with the value `F1` to the stack configuration using the command [`pulumi config set`](https://www.pulumi.com/docs/cli/commands/pulumi_config_set/)

<details>
  <summary>Command</summary>
  
  ```powershell
  pulumi config set AppServiceSku F1
  ```
</details>

The new setting is displayed in the dev stack configuration file: `Pulumi.dev.yaml`. 

2. Modify the code to retrieve the `AppServiceSku` setting and put it in the outputs (cf. [doc](https://www.pulumi.com/docs/concepts/config/#code)).

<details>
  <summary>Code to retrieve the configuration in C#</summary>
  
```csharp
var config = new Config();
var appServiceSku = config.Get("AppServiceSku");

return new Dictionary<string, object?>
{
   ["outputKey"] = "outputValue",
   ["appServiceSku"] = appServiceSku
};
```
</details>

<details>
  <summary>Code to retrieve the configuration in TypeScript</summary>
    
```typescript
import {Config} from "@pulumi/pulumi";

const config = new Config()
const appServiceSkuSetting = config.get("AppServiceSku")

export const outputKey = "outputValue"
export const appServiceSku = appServiceSkuSetting
```
</details>

<details>
  <summary>Code to retrieve the configuration in Python</summary>

```python
import pulumi 
from pulumi import Config


config = Config()
app_service_sku = config.get("AppServiceSku")

pulumi.export("outputKey", "outputValue")
pulumi.export("appServiceSku", app_service_sku)
```
</details>

> [!NOTE]  
> Run `pulumi up -y` (the `-y` option is to automatically approve the preview) to update the stack and verify your code is working as expected. This will not always be specified in the rest of the workshop.

Pulumi has built-in supports for [secrets](https://www.pulumi.com/docs/concepts/secrets/#secrets-1) that are encrypted in the state.

3.  Add a new secret setting `ExternalApiKey` with the value `SecretToBeKeptSecure` to the configuration and to the outputs.

<details>
  <summary>Command</summary>

```powershell
pulumi config set --secret ExternalApiKey SecretToBeKeptSecure
```
</details>

<details>
  <summary>Code in C#</summary>

```csharp
var config = new Config();
var appServiceSku = config.Get("AppServiceSku");
var externalApiKey = config.RequireSecret("ExternalApiKey");

return new Dictionary<string, object?>
{
   ["outputKey"] = "outputValue",
   ["appServiceSku"] = appServiceSku,
   ["apiKey"] = externalApiKey
};
```
</details>

<details>
  <summary>Code in TypeScript</summary>

```typescript
const config = new Config()
const appServiceSkuSetting = config.get("AppServiceSku")
const externalApiKey = config.requireSecret("ExternalApiKey")

export const outputKey = "outputValue"
export const appServiceSku = appServiceSkuSetting
export const apiKey = externalApiKey
```
</details>

<details>
  <summary>Code in Python</summary>

```python
config = Config()
app_service_sku = config.get("AppServiceSku")
external_api_key = config.require_secret("ExternalApiKey")

pulumi.export("outputKey", "outputValue")
pulumi.export("appServiceSku", app_service_sku)
pulumi.export("apiKey", external_api_key)
```
</details>

You can see that the secret is masked in the logs and that you have to use the command `pulumi stack output --show-secrets` to display it.

## Provision Azure resources

### Configure the program to use the Azure provider

[Providers](https://www.pulumi.com/docs/concepts/resources/providers/) are the packages that allow you to provision resources in cloud providers or SaaS. Each resource provider is specific to a cloud provider/SaaS. 

1. Add the [Azure Native Provider package](https://www.pulumi.com/registry/packages/azure-native/installation-configuration/#installation) to the project.

<details>
  <summary>Command for C#</summary>
  
```powershell
dotnet add package Pulumi.AzureNative
```
</details>

<details>
  <summary>Command for TypeScript</summary>

```powershell
pnpm add @pulumi/azure-native
```
</details>

<details>
  <summary>Command for Python</summary>

```powershell
pip install pulumi-azure-native
## Or if you use poetry :
## poetry add pulumi-azure-native
```
</details>

> [!NOTE]
> The package is big so it can take some time to download and install especially if you are using Node.js

Azure providers allows to configure a default location for Azure resources so that you don't need to specify it each time you create a new resource.

2.  Configure the [default location](https://www.pulumi.com/registry/packages/azure-native/installation-configuration/#set-configuration-using-pulumi-config) for your Azure resources.

<details>
  <summary>Command</summary>
  
```powershell
pulumi config set azure-native:location westeurope
```
</details>

> [!NOTE]  
> All azure locations can be listed using the following command: `az account list-locations -o table`

3. Ensure you are correctly logged in the azure CLI using the `az account show` command. Otherwise, use the `az login` command.  

### Work with Azure resources

You can explore all Azure resources in the [documentation of the Azure API Native Provider](https://www.pulumi.com/registry/packages/azure-native/api-docs/) to find the resources you want to create. 

1. Create a [resource group](https://www.pulumi.com/registry/packages/azure-native/api-docs/resources/resourcegroup/) named `rg-workshop` that will contain the resources you will create next.

<details>
  <summary>Code in C#</summary>

```csharp
var resourceGroup = new ResourceGroup("workshop");   
```
</details>

<details>
  <summary>Code in TypeScript</summary>

```typescript
import {ResourceGroup} from "@pulumi/azure-native/resources";

const resourceGroup = new ResourceGroup("workshop");
```
</details>

<details>
  <summary>Code in Python</summary>

```python
import pulumi_azure_native as azure_native

resource_group = azure_native.resources.ResourceGroup("workshop")
```
</details>
    
When executing the `pulumi up` command, you will see that pulumi detects there is a new resource to create. Apply the update and verify the resource group is created.

> [!NOTE]  
> You don't have to specify a location for the resource group, by default it will use the location you previously specified in the configuration.

2. [Configure the resource group](https://www.pulumi.com/registry/packages/azure-native/api-docs/resources/resourcegroup/#inputs) to have the tag `Type` with the value `Demo` and the tag `ProvisionedBy` with the value `Pulumi`. 

<details>
  <summary>Code in C#</summary>

  ```csharp
  var resourceGroup = new ResourceGroup("workshop", new()
  {
      Tags =
      {
          { "Type", "Demo" },
          { "ProvisionedBy", "Pulumi" }
      }
  });
  ```
</details>

<details>
  <summary>Code in TypeScript</summary>

```typescript
const resourceGroup = new ResourceGroup("workshop", {
  tags: {
    Type: "demo",
    ProvisionedBy: "Pulumi"
  }
});
```
</details>

<details>
  <summary>Code in Python</summary>

```python
resource_group = azure_native.resources.ResourceGroup(
    "workshop",
    tags={
        "Type": "Demo",
        "ProvisionedBy": "Pulumi",
    }
)
```
</details>

When updating the stack, you will see that pulumi detects the resource group needs to be updated.

It's a good practice to follow a [naming convention](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming). Like the name `rg-workshop-dev` where:
 - `rg` is the abbreviation for the resource type "resource group"
 - `workshop` is the name of the application/workload
 - `dev` is the name of the environment/stack

3. Update the resource group name to `rg-workshop-dev` for your resource group.

<details>
  <summary>Code in C#</summary>

```csharp
var stackName = Deployment.Instance.StackName;
var resourceGroup = new ResourceGroup($"rg-workshop-{stackName}", new()
{
    Tags =
    {
        { "Type", "Demo" },
        { "ProvisionedBy", "Pulumi" }
    }
});
```
  The stack name is directly retrieved from Pulumi to avoid hardcoding it.
</details>

<details>
  <summary>Code in TypeScript</summary>

```typescript
const stackName = pulumi.getStack()
const resourceGroup = new ResourceGroup(`rg-workshop-${stackName}`, {
  tags: {
    Type: "demo",
    ProvisionedBy: "Pulumi"
  }
});
```
The stack name is directly retrieved from Pulumi to avoid hardcoding it.
</details>

<details>
  <summary>Code in Python</summary>

```python
stack_name = pulumi.get_stack()

resource_group = azure_native.resources.ResourceGroup(
    f"rg-workshop-{stack_name}",
    tags={
        "Type": "Demo",
        "ProvisionedBy": "Pulumi",
    }
)
```
The stack name is directly retrieved from Pulumi to avoid hardcoding it.
</details>


When updating the stack, you will see that pulumi detects the resource group needs to be recreated (delete the one with the old name and create a new one with the new name). Indeed, when some input properties of a resource change, it triggers a replacement of the resource. The input properties concerned are always specified in the documentation of each resource.

> [!NOTE]  
> You have seen that depending on what you do, updating the stack will result in creating, updating, or deleting resources. Instead of executing the `pulumi up` command each time you want to see the result of your changes, you can use the [`pulumi watch`](https://www.pulumi.com/docs/cli/commands/pulumi_watch/) command that will act as [hot reload for your infrastructure code](https://www.techwatching.dev/posts/pulumi-watch) (each time you make a change and save your code file, pulumi will detect it, build the code, and deploy the changes ). You can use that for the rest of the workshop or continue using `pulumi up -y` if you prefer.

Sometimes it's not easy to find the correct type for the resource we want to create. You can use the [`pulumi ai web`](https://www.pulumi.com/blog/pulumi-insights-ai-cli/#pulumi-ai-in-the-cli) command to use natural-language prompts to generate Pulumi infrastructure-as-code. 

4. Use pulumi ai to provision a free Web App/App Service.

<details>
  <summary>Command for C#</summary>
  
```powershell
pulumi ai web -l C# "Using Azure Native Provider, create a free App Service."
```
</details>

<details>
  <summary>Command for TypeScript</summary>

```powershell
pulumi ai web -l typescript "Using Azure Native Provider, create a free App Service."
```
</details>

<details>
  <summary>Command for Python</summary>

```powershell
pulumi ai web -l python "Using Azure Native Provider, create a free App Service."
```
</details>

<details>
  <summary>Code in C#</summary>

```csharp
var appServicePlan = new AppServicePlan($"sp-workshop-{stackName}", new()
{
    ResourceGroupName = resourceGroup.Name,
    Sku = new SkuDescriptionArgs()
    {
        Name = "F1",
    },
});

var appService = new WebApp($"app-workshop-{stackName}", new()
{
    ResourceGroupName = resourceGroup.Name,
    ServerFarmId = appServicePlan.Id,
});
```
  An [App Service Plan](https://www.pulumi.com/registry/packages/azure-native/api-docs/web/appserviceplan/) is needed to create an [App Service](https://www.pulumi.com/registry/packages/azure-native/api-docs/web/webapp/). 
</details>

<details>
  <summary>Code in TypeScript</summary>

```typescript
const appServicePlan = new AppServicePlan(`sp-workshop-${stackName}`, {
  resourceGroupName: resourceGroup.name,
  sku: {
    name: "F1",
  },
});

const appService = new WebApp(`app-workshop-${stackName}`, {
  resourceGroupName: resourceGroup.name,
  serverFarmId: appServicePlan.id,
});
```
An [App Service Plan](https://www.pulumi.com/registry/packages/azure-native/api-docs/web/appserviceplan/) is needed to create an [App Service](https://www.pulumi.com/registry/packages/azure-native/api-docs/web/webapp/).
</details>

<details>
  <summary>Code in Python</summary>

```python
app_service_plan = azure_native.web.AppServicePlan(
    f"sp-workshop-{stack_name}",
    resource_group_name=resource_group.name
    sku=azure_native.web.SkuDescriptionArgs(
        name="F1"
    )
)

app_service = azure_native.web.WebApp(
    f"app-workshop-{stack_name}",
    resource_group_name=resource_group.name,
    server_farm_id=app_service_plan.id
)
```
</details>

> [!NOTE]  
> To access properties from other resources, you can just use variables.

5. Update the infrastructure to use the `AppServiceSku` setting from the configuration instead of hard coding the SKU `F1`.

<details>
  <summary>Code in C#</summary>

```csharp
var appServiceSku = config.Require("AppServiceSku");
var appServicePlan = new AppServicePlan($"sp-workshop-{stackName}", new()
{
    ResourceGroupName = resourceGroup.Name,
    Sku = new SkuDescriptionArgs()
    {
        Name = appServiceSku,
    },
});
```
</details>

<details>
  <summary>Code in TypeScript</summary>

```typescript
const appServiceSku = config.require("AppServiceSku")
const appServicePlan = new AppServicePlan("appServicePlan", {
  resourceGroupName: resourceGroup.name,
  sku: {
    name: appServiceSku,
  },
});
```
</details>

<details>
  <summary>Code in Python</summary>

```python
app_service_sku = config.require("AppServiceSku")
app_service_plan = azure_native.web.AppServicePlan(
    f"sp-workshop-{stack_name}",
    resource_group_name=resource_group.name,
    sku=azure_native.web.SkuDescriptionArgs(
        name=app_service_sku
    )
)
```
</details>

Not only does the stack have outputs, but the resources themselves also have outputs, which are properties returned from the cloud provider. Since these values are only known once the resources have been provisioned, there are certain [considerations](https://www.pulumi.com/docs/concepts/inputs-outputs/#outputs) to keep in mind when using them in your program (particularly when performing computations based on an output).

6. Modify the program to make the stack only return one output, that is the URL of the app service.

<details>
  <summary>Code in C#</summary>

```csharp
var appService = new WebApp($"app-workshop-{stackName}", new WebAppArgs
{
    ResourceGroupName = resourceGroup.Name,
    ServerFarmId = appServicePlan.Id,
});

return new Dictionary<string, object?>
{
    ["AppServiceUrl"] = Output.Format($"https://{appService.DefaultHostName}")
};
```
</details>

<details>
  <summary>Code in TypeScript</summary>

```typescript
const appService = new WebApp("appService", {
  resourceGroupName: resourceGroup.name,
  serverFarmId: appServicePlan.id,
});

export const appServiceUrl = pulumi.interpolate`https://${appService.defaultHostName}`;
```
</details>

<details>
  <summary>Code in Python</summary>

```python
app_service = azure_native.web.WebApp(
    f"app-workshop-{stack_name}",
    resource_group_name=resource_group.name,
    server_farm_id=app_service_plan.id
)

pulumi.export("app_service_url", app_service.default_host_name.apply(lambda hostname: f"http://{hostname}"))
```
</details>

Sometimes, you need some data that are not available as properties of a resource. That's exactly what [provider functions](https://www.pulumi.com/docs/concepts/resources/functions/#provider-functions) are for. For instance, the [ListWebAppPublishingCredentialsOutput](https://www.pulumi.com/registry/packages/azure-native/api-docs/web/listwebapppublishingcredentials/) function can be used to retrieve the [publishing credentials](https://github.com/projectkudu/kudu/wiki/Deployment-credentials#site-credentials-aka-publish-profile-credentials) of an App Service

7. Add 2 outputs to the stack `PublishingUsername` and `PublishingUserPassword` that are secrets that can be used to deploy a zip package to the App Service.

<details>
  <summary>Code in C#</summary>

```csharp
var publishingCredentials = ListWebAppPublishingCredentials.Invoke(new()  
{  
    ResourceGroupName = resourceGroup.Name,  
    Name = appService.Name  
});

return new Dictionary<string, object?>
{
    ["AppServiceUrl"] = Output.Format($"https://{appService.DefaultHostName}"),
    ["PublishingUsername"] = Output.CreateSecret(publishingCredentials.Apply(c => c.PublishingUserName)), 
    ["PublishingUserPassword"] = Output.CreateSecret(publishingCredentials.Apply(c => c.PublishingPassword)),
};
```
  As the function outputs are not marked as secrets, you have to manually do it.
</details>

<details>
  <summary>Code in TypeScript</summary>

```typescript
const publishingCredentials = listWebAppPublishingCredentialsOutput({
  name: appService.name,
  resourceGroupName: resourceGroup.name
})

export const appServiceUrl = pulumi.interpolate`https://${appService.defaultHostName}`;
export const publishingUsername = pulumi.secret(publishingCredentials.publishingUserName)
export const publishingPassword = pulumi.secret(publishingCredentials.publishingPassword)
```
As the function outputs are not marked as secrets, you have to manually do it.
</details>

<details>
  <summary>Code in Python</summary>

```python
publishing_credentials = azure_native.web.list_web_app_publishing_credentials(
    resource_group_name=resource_group.name,
    name=app_service.name
)

pulumi.export("app_service_url", app_service.default_host_name.apply(lambda hostname: f"http://{hostname}"))
pulumi.export("publishing_username", Output.secret(publishing_credentials.publishing_user_name))
pulumi.export("publishing_userpassword", Output.secret(publishing_credentials.publishing_password))
```
As the function outputs are not marked as secrets, you have to manually do it.
</details>

## Manage stacks

- Use the `pulumi about` command to get some information about the current Pulumi environment.
It also displays information about the current stack.

### Create a new stack

- Use the [`pulumi stack init`](https://www.pulumi.com/docs/iac/cli/commands/pulumi_stack/) command to create a new `prod` stack.

<details>
  <summary>Command</summary>

```powershell
pulumi stack init prod
```
</details>

You will be automatically switched to his new stack. You can switch back to the previous stack using the `pulumi stack select` command.

- Switch back to the `dev` stack

<details>
  <summary>Command</summary>

```powershell
pulumi stack select dev
```
</details>

- List the different stacks with the `pulumi stack ls` command.

### Provision the infrastructure for a new environment

- Select the `prod` stack and try to provision the infrastructure for this stack. It should fail because some configuration is missing.

<details>
  <summary>Command</summary>

```powershell
pulumi stack select prod
pulumi up
```
</details>

- Add the missing configuration and provision the infrastructure

<details>
  <summary>Command</summary>

```powershell
pulumi config set azure-native:location westeurope
pulumi config set --secret ExternalApiKey SecretToBeKeptVerySecure
pulumi config set AppServiceSku F1
pulumi up
```
</details>

> [!NOTE]
> You are on another environment so you don't have to set the same values. You can use another sku, another default azure location, another secret value... 


### Delete resources and stack

To delete all the resources in the stack you can run the command `pulumi destroy`.

- Delete the resources on the `prod` environment.

If you want to delete the stack itself with its configuration and deployment history you can run the command `pulumi stack rm` command.

- Delete the `prod` stack

<details>
  <summary>Command</summary>

```powershell
pulumi stack rm prod
```
</details>

## Next

To continue this lab and see more advanced features, you can check the next parts:
- [Use Pulumi in CI/CD Pipelines with GitHub Actions](/CI_CD.md)