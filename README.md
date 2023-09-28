# Getting Started Provisionning Infrastructure on Azure with Pulumi

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

```pwsh
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
winget install Microsoft.DotNet.SDK.7
```

### Choose a backend

As Pulumi is a declarative IaC solution that uses a state to manage the cloud resources, a place to store this state is needed: the "backend". An encryption provider is also needed to encrypt that will be used. You can check this [article in the documentation](https://www.pulumi.com/docs/concepts/state/#managing-state-backend-options) to see the different backends and encryption providers available. 

The most convenient way of doing this workshop without worrying about configuring a backend or an encryption provider is to use Pulumi Cloud which is free for individuals. You can just create an account [here](https://app.pulumi.com/signup) (or sign in using your GitHub/GitLab account) and that's it.

If you don't want to use Pulumi Cloud, that's totally fine too, check the documentation or this [article](https://www.techwatching.dev/posts/pulumi-azure-backend) that demonstrates how to use Pulumi with Azure Blob Storage as the backend  and Azure Key Vault as the encryption provider (script to configure these resources is available at the end of the article).

## Pulumi fundamentals

## Create a basic Pulumi project

1. Create a new directory
```pwsh
mkdir infra; cd infra
```

2. List the available templates
```pwsh
pulumi new -l
```

There are several azure templates (prefixed by azure) that are already configured to provision resources to Azure, but for the purpose of this workshop you will start a project from scratch to better understand how everything works.

3. Create a new Pulumi project using an empty template (corresponding to the language of your choice)
```pwsh
pulumi new csharp -n PulumiAzureWorkshop -s dev -d "Workshop to learn Pulumi with Azure fundamentals"
```

The `-s dev` option is used to initialize the project with a stack named `dev`. A [stack](https://www.pulumi.com/docs/concepts/stack/#stacks) is an independently configurable instance of a Pulumi program. Stacks are mainly use to have a different instance for each environment (dev, staging, preprod, prod ...). or for [each developer making changes to the infrastructure](https://www.pulumi.com/blog/iac-recommended-practices-developer-stacks-git-branches/#using-developer-stacks).

> [!NOTE]  
> You will problably be prompted to log in to Pulumi Cloud when running this command. Just use your GitHub/GitLab account or the credentials of the account you previously created. If you use a selfhosted backend, log in with the appropriate backend url before running the `pulumi new` command.

Open the project in your favorite IDE to browse the files.

### Deploy a stack

Use [`pulumi up`](https://www.pulumi.com/docs/cli/commands/pulumi_up/) to deploy the stack

The command will first display a preview of the changes and then ask you wether or not you want to apply the changes. Select yes.

As there are currenlty no resources in the Pulumi program, only the stack itself will be created in the state, no cloud resources will be provisioned.

However, the Pulumi program contains an output "outputKey" that is displayed once the command is executed. [Outputs](https://www.pulumi.com/learn/building-with-pulumi/stack-outputs/) can be used to retrieve information from a Pulumi stack like URL from provisioned cloud resources.

### Handle configuration, outputs, and secrets

1. [Configuration](https://www.pulumi.com/docs/concepts/config/) allows you to configure resources with different settings depending on the stack you are using. A basic use case is to have the pricing tier of a resource in the configuration to have less expensive/powerful machines in the development environmenet than in production. Add a setting named `AppServiceSku` with the value `Free` to the the stack configuration using the command [`pulumi config set`](https://www.pulumi.com/docs/cli/commands/pulumi_config_set/)

<details>
  <summary>Command</summary>
  
  ```pwsh
  pulumi config set AppServiceSku Free
  ```
</details>

The new setting is displayed in the dev stack configuration file: `Pulumi.dev.yaml`. 

2. Modify the code to retrieve the `AppServiceSku` setting and put it in the ouputs (cf. [doc](https://www.pulumi.com/docs/concepts/config/#code)).

<details>
  <summary>Code to retrieve the configuration</summary>
  
  ```csharp
  var config = new Config();
  var appServiceSku = config.Get("AppServiceSku");

  return new Dictionary<string, object?>
  {
     ["outputKey"] = "outputValue",
     ["outputSku"] = appServiceSku
  };
  ```
</details>

> [!NOTE]  
> Run `pulumi up -y` (the `-y` option is to automatically approve the preview) to update the stack and verify your code is working as expected. This will not always be specified in the rest of the workshop.

3. Pulumi has built-in supports for [secrets](https://www.pulumi.com/docs/concepts/secrets/#secrets-1) that are encrypted in the state. Add a new secret setting `ExternalApiKey` with the value `SecretToBeKeptSecure` to the configuration and to the outputs.

<details>
  <summary>Command</summary>
  
  ```pwsh
  pulumi config set --secret ExternalApiKey SecretToBeKeptSecure
  ```

  ```csharp
   var config = new Config();
   var appServiceSku = config.Get("AppServiceSku");
   var externalApiKey = config.RequireSecret("ExternalApiKey");

   return new Dictionary<string, object?>
   {
      ["outputKey"] = "outputValue",
      ["outputSku"] = appServiceSku,
      ["outputApiKey"] = externalApiKey
   };
  ```
</details>

You can see that the secret is masked in the logs and that you have to use the command `pulumi stack output --show-secrets` to display it.

## Provision Azure resources

1. Add the [Azure Native Provider package](https://www.pulumi.com/registry/packages/azure-native/installation-configuration/#installation) to the project.

<details>
  <summary>Command</summary>
  
  ```pwsh
  dotnet add package Pulumi.AzureNative
  ```
</details>