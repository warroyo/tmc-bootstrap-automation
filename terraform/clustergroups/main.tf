locals {
    cluster_files = fileset(var.cluster_files_path,"*.yaml")   
    yaml_data  = { for f in local.cluster_files : f => yamldecode(file("${var.cluster_files_path}/${f}")) }  
    filtered_data = { for k,v in local.yaml_data: v.product_team => v... }
}


# Create Tanzu Mission Control cluster group

resource "tanzu-mission-control_cluster_group" "create_cluster_group" {
  for_each = local.filtered_data
  name = each.key
  meta {
    description = "Create cluster group through terraform"
    labels = {
      "cloud" : "public",
      "automation" : "terraform"
    }
  }
}

module "workspace" {
  for_each = local.filtered_data
  source = "../modules/workspace/"
  workspace_name = tanzu-mission-control_cluster_group.create_cluster_group[each.key].name
  ad_groups = each.value[0].ad_groups
}

# create all of the needed permissions,policy,secrets, gitops etc.
module "cg_bootstrap" {
  for_each = local.filtered_data
  source = "../modules/cluster_bootstrap/"
  cluster_group = tanzu-mission-control_cluster_group.create_cluster_group[each.key].name
  infra_gitops_repo = "https://github.com/warroyo/tmc-bootstrap-automation"
}