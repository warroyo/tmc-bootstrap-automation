module "enforce-sa-template" {
  source = "../modules/tmc_custom_policy_template"
  template-file = abspath("${path.module}/templates/enforce-sa-template.yaml")
}