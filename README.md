# TMC cluster bootstrapping

This repo provides an example of provisioning TKGs clusters using TMC Terraform and gitops. This takes an opinionated approach of having a dedicated workspace and clustergroup per product team(dev team). However, the `modules` directory has re-usable code that could be used to implement a different approach. This is purely an example of one way to automate clusters and onboard teams, there are many approaches that could be taken depending on your organizations structure and needs.   


## Pre-reqs

* azure account -  this is needed to store state, secrets and run ADO pipelines.
* TMC organization


## What does this repo do?

This repo sets up the following:

1. Simple yaml file input to drive onboarding of new teams
2. Terraform for automating the following in TMC for new onbaording teams
   1. cluster groups
   2. clusters
   3. CD & Helm config 
   4. IAM roles
   5. Policy templates
   6. Policies
   7. Iam permissions
   8. workspaces
   9. default namespace for the team in each cluster
3. Minimal Flux directory structure for installing the following
   1. contour
   2. cert manager
4. Flux templating for generating cluster and cluster group specific files/directories based on terraform output
5. azure pipeline to automate everything using ADO. 

## Setup

### Setup an ADO project

Create a new ADO project or use an existing one. 

1. Enable the  [Terraform Task](https://marketplace.visualstudio.com/items?itemName=ms-devlabs.custom-terraform-tasks) in your ADO organization
2. [create a service connection](https://learn.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml#create-a-service-connection) for your azure subscription in the ADO project. This will be used in the azure pipelines yaml. This should be an Azure RM servcie connetcion. also select "grant permissions to all pipelines". use the appropriate auth method for your organization
3. Update the `azure-pipelines.yml` file to use the correct service connection name


### Setup azure state store and secret storage

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


### Create the initial secrets

We need secrets some initial secrets for bootstrapping the cluster prior to flux taking over.

#### TMC credentials

The TMC credentials will be used for the TMC terraform provider.

1. create the TMC secrets in the previously created vault

```bash
#the endpoint should just be the tmc hostname without the https://
az keyvault secret set --vault-name "terraform-secrets01" --name "tmc-endpoint" --value "<tmc-endpoint>"
az keyvault secret set --vault-name "terraform-secrets01" --name "tmc-api-key" --value "<tmc-api-key>"
```

#### Github PAT

This can be used for private repos as well as for creating the PR at the end of the pipeline.

```bash
az keyvault secret set --vault-name "terraform-secrets01" --name "github-pat" --value "<github token>"
```

### Create a base pipeline for the git repo

In the ADO project create a new pipeline and select your repo. You will need to authorize your azure account to connect to github repos. Once conected you should see the repos and you can now select this repo and the azure-pipelines.yaml, it should automatically pick this up.

#### Add a github PAT

This is needed to that the github CLI can be used from the azure pipelines. Currently there is not a way to use the existing service connection for this unfortunately.

1. create a variable group
2. select to use secrets from AKV
3. choose the terraform akv and the  github pat created in the previous step


## Usage

Once the basics are setup using the steps above the usage of this repo is very simple. All automation is done through the `cluster_yaml` directory. Place new files in there as needed with the necessary inputs and clusters will be created an onboarded. This folder can be overridden with an external folder by updating the terraform variable `cluster_files_path`.


## Customization

This repo is meant to be an example and it is expected that it will be forked and customized. The key directories are laid out below with some info about them to help in determining what might need to be changed.

`cluster_yaml` -  keeps the yaml files that the terraform uses to read inputs.
`flux` -  the main flux directory structure that gets setup as the `infra-base` kustomization in TMC. This contains a repo structure that starts with cluster groups and then sets up individual cluster kustomizations dynamically.
`flux-templating` - this directory contains all of the templates for new clusters/cluster groups the ADO pipeline uses the `copier` OSS tool for stamping out the new directories and files when there is a new cluster or cluster group created by TF. this is where you can create the default gitops config for new clusters. These files/dirs are copied into `flux` during the pipeline run and committed to the repo.
`terraform` - contains all of the terraform for TMC. `main.tf` is the starting point. 
`azure-pipelines.yml` - pipeline that runs all of the TF anf the templating scripts.
 


## Templating new clusters and cluster groups

When creating clusters and cluster groups we also need to generate some flux directroy structure and files. For this we are using a tool call [copier](https://copier.readthedocs.io/en/stable/). The directory `flux-templating` is where all of the templates exist. In the pipeline run there is a templating step that will execute copier via python script and generate the needed files/directories based on the terraform output. The script that runs this can be found in the `pipeline-scripts` folder. This will not overwrite files after they are created, this is done by design since you may want to change the clusters flux behavior independently afterwards. This generation is purely to speed up the onboarding process.

## Working locally

1. `cd terraform`
2. init using the azure backend
```bash
terraform init -backend-config=storage_account_name=<storage-account> -backend-config=container_name=tfstate -backend-config=key=terraform.tfstate -backend-config=resource_group_name=<resource-group> -backend-config=subscription_id=<subscription-id> -backend-config=tenant_id=<tenant-id>
```