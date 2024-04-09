# TMC cluster bootstrapping

This repo provides an example of provisioning TKGs clusters using TMC Terraform and gitops. This takes an opinionated approach of having a dedicated workspace and clustergroup per product team. However, the `modules` directory has re-usable code that could be used to implement a different approach. This is purely an example of one way to automate clusters and onboard teams, there are many approaches that could be taken depending on your organizations structure and needs.   


## Pre-reqs

* azure account -  this is needed to store state, secrets and run ADO pipelines.
* TMC organization


##

## Setup an ADO project

Create a new ADO project or use an existing one. 

1. Enable the  [Terraform Task](https://marketplace.visualstudio.com/items?itemName=ms-devlabs.custom-terraform-tasks) in your ADO organization
2. [create a service connection](https://learn.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml#create-a-service-connection) for your azure subscription in the ADO project. This will be used in the azure pipelines yaml. This should be an Azure RM servcie connetcion. also select "grant permissions to all pipelines". use the appropriate auth method for your organization
3. Update the `azure-pipelines.yml` file to use the correct service connection name


## Setup azure state store and secret storage

```bash
az login
```

setup env vars for the resources we will create.

```bash
export RESOURCE_GROUP_NAME='tmc-bootstrap-automation'
export STORAGE_ACCOUNT_NAME="tfstate01tmc"
export CONTAINER_NAME='tfstate'
```

1. create or use an existing resource group
   
```bash
# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location eastus
```
2. create the storage account and container

```bash
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob

# Create blob container
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME

```

3. create the keyvault for the TF secrets. The vault name needs to be globally unique so you will need to change the name

```bash
az keyvault create --name "terraform-secrets01" --resource-group $RESOURCE_GROUP_NAME --location "EastUS"

```

4. get the SP that was created for your service connection in the pre-reqs. this can be found by looking at the service connection in ADO and clicking the link to "manage service prinipal" use that name to get the object ID

```bash
az ad sp list --display-name "service-connection-sp-name"
```

5. assign permissions to the sp on the keyvault


```bash
az role assignment create --role "Key Vault Secrets User" --assignee 9f10801d-9640-4399-9ffb-6f69b369bbba --scope /subscriptions/31f60aa7-0ea5-47af-85b2-27e792a36288/resourcegroups/$RESOURCE_GROUP_NAME/providers/Microsoft.KeyVault/vaults/terraform-secrets01

```


## Create the initial secrets

We need secrets some initial secrets for bootstrapping the cluster prior to flux taking over.

### TMC credentials

The TMC credentials will be used for the TMC terraform provider.

1. create the TMC secrets in the previously created vault

```bash
#the endpoint should just be the tmc hostname without the https://
az keyvault secret set --vault-name "terraform-secrets01" --name "tmc-endpoint" --value "<tmc-endpoint>"
az keyvault secret set --vault-name "terraform-secrets01" --name "tmc-api-key" --value "<tmc-api-key>"
```

## Create a base pipeline for the git repo

In the ADO project create a new pipeline and select your repo and the azure-pipelines.yaml, it should automatically pick this up.

## Templating new clusters and cluster groups

When creating clusters and cluster groups we also need to generate some flux directroy structure and files. For this we are using a tool call [copier](https://copier.readthedocs.io/en/stable/). the directory `flux-templating` is where all of the templates exist. In the pipeline run there is a templating step that will execute copier via python script and generate the needed files/directories based on the terraform output. The script that runs this can be found in the `pipeline-scripts` folder. 

## Working locally

1. `cd terraform`
2. init using the azure backend
```bash
terraform init -backend-config=storage_account_name=<storage-account> -backend-config=container_name=tfstate -backend-config=key=terraform.tfstate -backend-config=resource_group_name=<resource-group> -backend-config=subscription_id=<subscription-id> -backend-config=tenant_id=<tenant-id>
```