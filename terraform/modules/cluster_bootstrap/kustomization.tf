# Create Tanzu Mission Control kustomization with attached set as default value.
resource "tanzu-mission-control_kustomization" "create_cluster_group_kustomization" {
  name = "infra-base" # Required

  namespace_name = "tanzu-continuousdelivery-resources" #Required

  scope {
    cluster_group {
      name = var.cluster_group
    }
  }

    spec {
    path = "flux/clustergroups/${var.cluster_group}" # Required
    prune = true
    interval = "5m" # Default: 5m
    source {
       name = "infra-gitops" # Required
       namespace = "tanzu-continuousdelivery-resources" # Required
    }
  }

  depends_on = [tanzu-mission-control_git_repository.create_cluster_group_git_repository]


}



module "enable-helm" {
  source = "../tmc-helm"
  cluster_group = var.cluster_group
}