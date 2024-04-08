
module "enforce-sa-policy-test" {
 source = "../tmc_custom_policy"
  cluster_group =  var.cluster_group
  policy_name = "fluxenforcesa"
  template_name = "fluxenforcesa2"

  target_kubernetes_resources = [
    {
      api_groups = ["kustomize.toolkit.fluxcd.io"]
      kinds = ["Kustomization"]
    },
    {
      api_groups = [" helm.toolkit.fluxcd.io"]
      kinds = ["HelmRelease"]
    }
  ]

  match_expressions = [
    {
      values = ["tanzu-continuousdelivery-resources"]
      key = "kubernetes.io/metadata.name"
      operator = "NotIn"
    }
  ]

}

