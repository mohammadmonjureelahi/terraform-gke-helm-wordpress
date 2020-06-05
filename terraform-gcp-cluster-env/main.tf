module "vault" {
  source               = "../modules/terraform-module-vault" # ../ move up a folder look in modules/terraform-module-vault
  gcp_json             = var.cluster_gcp_json

  cluster_project_id   = var.project_id
  cluster_region       = "northamerica-northeast1"
  cluster_zone         = "northamerica-northeast1-a"

  environment          = "vault" # You will need to manually create this namespace IE: kubectl create namespace vault
  replicas             = 2
  helm_version         = var.vault_version
  force_destroy_bucket = true # This is a dangerous setting and is only true while testing, It deletes a bucket with content in it
  bucket_name          = "project-name-vault-backend"
  vault_ui             = "false"
}
