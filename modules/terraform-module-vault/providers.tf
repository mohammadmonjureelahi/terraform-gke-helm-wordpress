provider "google" {
  credentials = base64decode(var.gcp_json)
  project     = var.cluster_project_id
  region      = var.cluster_region
  zone        = var.cluster_zone
}

provider "google-beta" {
  credentials = base64decode(var.gcp_json)
  project     = var.cluster_project_id
  region      = var.cluster_region
  zone        = var.cluster_zone
}
