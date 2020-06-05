resource "google_storage_bucket" "vault_bucket" {
  name               = var.bucket_name
  project            = var.cluster_project_id
  location           = var.cluster_region
  force_destroy      = var.force_destroy_bucket
}