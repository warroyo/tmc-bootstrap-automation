

locals {
  tmc-api-key = data.azurerm_key_vault_secret.tmc-api-key.value
  tmc-endpoint = data.azurerm_key_vault_secret.tmc-endpoint.value
}


variable "cluster_files_path" {
  type = string
  default = "../cluster_yaml"
}