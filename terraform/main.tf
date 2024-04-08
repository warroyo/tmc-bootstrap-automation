data "azurerm_key_vault" "terraform-secrets" {
  name                = "terraform-secrets01"
  resource_group_name = "tmc-bootstrap-automation"
}
data "azurerm_key_vault_secret" "tmc-endpoint" {
  name         = "tmc-endpoint"
  key_vault_id = data.azurerm_key_vault.terraform-secrets.id
}

data "azurerm_key_vault_secret" "tmc-api-key" {
  name         = "tmc-api-key"
  key_vault_id = data.azurerm_key_vault.terraform-secrets.id
}

#create any custom IAM roles
module "iam_roles" {
source = "./iam_roles"
}

# # create any custom policy templates
module "policy_templates" {
source = "./policy_templates"
}

module "cluster_groups" {
  source = "./clustergroups"
  depends_on = [ module.policy_templates,module.iam_roles ]
  cluster_files_path = var.cluster_files_path
}


module "clusters" {
  source = "./clusters"
  depends_on = [ module.cluster_groups ]
  cluster_files_path = var.cluster_files_path

}

output "cluster_names" {
  value = module.clusters.cluster_names
}