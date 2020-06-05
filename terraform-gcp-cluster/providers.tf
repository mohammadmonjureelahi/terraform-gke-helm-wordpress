provider "google" {
  version     = "v3.15.0"
  credentials = base64decode(var.sasp_sql_development_gcp_json)
  project     = var.project_id
  region      = "northamerica-northeast1"
  zone        = "northamerica-northeast1-a"
}

provider "google-beta" {
  version     = "v3.15.0"
  credentials = base64decode(var.sasp_sql_development_gcp_json)
  project     = var.project_id
  region      = "northamerica-northeast1"
  zone        = "northamerica-northeast1-a"
}

provider "kubernetes" {
  # version = "1.10.0"
  host    = module.gcp_cluster.endpoint
  token   = module.gcp_cluster.token
  cluster_ca_certificate = base64decode(
    module.gcp_cluster.cluster_ca_certificate
  )
}
