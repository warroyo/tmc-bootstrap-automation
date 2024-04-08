resource "tanzu-mission-control_workspace" "workspace" {
  name = var.workspace_name

  meta {
    description = "Create workspace through terraform"
    labels = {
      "mode" : "automation",
      "platform" : "terraform-test"
    }
  }
}

/*
 Workspace scoped Tanzu Mission Control IAM policy.
 This resource is applied on a workspace to provision the role bindings on the associated workspace.
 The defined scope block can be updated to change the access policy's scope.
 */
resource "tanzu-mission-control_iam_policy" "workspace-cluster-admin-policy" {
  scope {
    workspace {
      name = tanzu-mission-control_workspace.workspace.name
    }
  }

  role_bindings {
    role = "cluster-admin-equiv-2"
    subjects {
      name = "${tanzu-mission-control_workspace.workspace.name}:tenant-flux-reconciler"
      kind = "K8S_SERVICEACCOUNT"
    }
    dynamic "subjects" {
        for_each = var.ad_groups
        content {
        name = subjects.value
        kind = "GROUP"
        }
    }
  }
}

