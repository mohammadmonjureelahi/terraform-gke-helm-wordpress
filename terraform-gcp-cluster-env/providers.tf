provider "google" {
  version     = "v3.15.0"
  credentials = base64decode(var.cluster_gcp_json)
  project     = var.project_id
  region      = "northamerica-northeast1"
  zone        = "northamerica-northeast1-a"
}

provider "google-beta" {
  version     = "v3.15.0"
  credentials = base64decode(var.cluster_gcp_json)
  project     = var.project_id
  region      = "northamerica-northeast1"
  zone        = "northamerica-northeast1-a"
}

data "google_client_config" "default" {}

data "google_container_cluster" "prd" {
  name   = "kubernetes-cluster" # This is how this env repo knows which cluster to attempt to deploy too
  region = "northamerica-northeast1"
}

provider "kubernetes" {
  version                = "v1.9"
  load_config_file       = false
  host                   = "https://${data.google_container_cluster.prd.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.prd.master_auth.0.cluster_ca_certificate)
}

provider "helm" {
  version        = "v1.1.1"
  debug = true
  kubernetes {
    load_config_file = false
    host  = "https://${data.google_container_cluster.prd.endpoint}"
    token = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(
      data.google_container_cluster.prd.master_auth.0.cluster_ca_certificate
    )
  }
}
