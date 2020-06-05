resource "google_container_cluster" "gcp_cluster" {
  depends_on = [
    google_project_service.kubernetes_api,
  ]
  name     = var.cluster_name
  location = var.cluster_region

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  master_auth {
    username = var.master_username
    password = var.master_password

    client_certificate_config {
      issue_client_certificate = true
    }
  }
}

resource "google_container_node_pool" "gcp_cluster_nodes" {
  name       = var.nodepool_name
  location   = var.cluster_region
  cluster    = google_container_cluster.gcp_cluster.name
  node_count = var.nodepool_count

  node_config {
    preemptible  = var.nodepool_preemptible
    machine_type = var.nodepool_size

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

data "google_client_config" "default" {
}
