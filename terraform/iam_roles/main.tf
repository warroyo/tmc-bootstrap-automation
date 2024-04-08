
resource "tanzu-mission-control_custom_iam_role" "cluster_admi_equiv" {
  name = "cluster-admin-equiv-2"

  spec {
    is_deprecated = false

    allowed_scopes = [
      "NAMESPACE",
      "WORKSPACE"
    ]

    tanzu_permissions = [
      "cluster.namespace.get",
      "cluster.namespace.iam.get",
      "cluster.namespace.iam.set",
      "cluster.namespace.policy.get"
    ]

    kubernetes_permissions {
      rule {
        resources  = ["*"]
        verbs      = ["*"]
        api_groups = ["*"]
      }
      rule {
        url_paths  = ["/*"]
        verbs      = ["*"]
        api_groups = ["*"]
      }
    }
  }
}