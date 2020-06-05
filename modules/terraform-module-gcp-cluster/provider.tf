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

provider "kubernetes" {
  version                = "v1.9"
  load_config_file       = false
  host                   = "https://${data.google_container_cluster.prd.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.prd.master_auth.0.cluster_ca_certificate)
}