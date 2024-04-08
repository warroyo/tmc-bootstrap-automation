# Create Tanzu Mission Control git repository with attached set as default value.
resource "tanzu-mission-control_git_repository" "create_cluster_group_git_repository" {
  name = "infra-gitops" # Required

  namespace_name = "tanzu-continuousdelivery-resources" #Required

  scope {
    cluster_group {
      name = var.cluster_group
    }
  }

  spec {
    url = var.infra_gitops_repo # Required
    #secret_ref = "testSourceSecret"
    interval = "5m" # Default: 5m
    git_implementation = "GO_GIT" # Default: GO_GIT
    ref {
      branch = "main" 
    #   tag = "testTag"
    #   semver = "testSemver"
    #   commit = "testCommit"
    } 
  }
}
