
locals {
    cluster_files = fileset(var.cluster_files_path,"*.yaml")   
    yaml_data  = { for f in local.cluster_files : f => yamldecode(file("${var.cluster_files_path}/${f}")) }  
    filtered_data = { for k,v in local.yaml_data: k => v}
}

# create all clusters based on yaml files loaded above
module "clusters" {
  for_each = local.filtered_data
  source = "../modules/tmc_tkgs_cluster"
  management_cluster_name = each.value.mgmt_cluster
  cluster_name = "tkg-${each.value.product_team}-cluster"
  provisioner_name = each.value.provisioner
  storage_class = "vc01cl01-t0compute"
  cp_replicas = 3
  cp_vm_class = "best-effort-medium"
  np_replicas = 3
  ntp = "time2.oc.vmware.com"
  np_vm_class = "best-effort-xlarge"
  cluster_group = each.value.product_team
  k8s_version = each.value.k8s_version
}

#create a default namespace for the product team
resource "tanzu-mission-control_namespace" "create_namespace" {
  for_each = local.filtered_data
  name                    = each.value.product_team 
  cluster_name            = module.clusters[each.key].cluster_name
  provisioner_name        = each.value.provisioner   
  management_cluster_name = each.value.mgmt_cluster 

  spec {
    workspace_name = each.value.product_team 
  }
}

output "cluster_names" {
  value = [ for cluster in module.clusters : cluster.cluster_name ]
}