resource "google_project_service" "cloudresourcemanager_api" {
  project                    = var.cluster_project_id
  service                    = "cloudresourcemanager.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "kubernetes_api" {
  depends_on = [
    google_project_service.cloudresourcemanager_api,
  ]
  project                    = var.cluster_project_id
  service                    = "container.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}