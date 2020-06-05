module "gcp_cluster" {
  source   = "../modules/terraform-module-gcp-cluster" # ../ move up a folder look in modules/terraform-module-gcp-cluster
  gcp_json = var.cluster_gcp_json

  cluster_project_id = var.project_id
  cluster_name       = var.kubernetes_cluster_name
  cluster_region     = "northamerica-northeast1" # This can be any valid GCP region we choose to create in canadian location (international data travel cost more)
  cluster_zone       = "northamerica-northeast1-a" # The region in canadian servers that gcp offers
  master_username    = "kubernetes-admin" # Just a service account name to create in kubernetes so terraform can perform kubernetes actions
  master_password    = var.master_password # Password for master_username

  nodepool_name  = "default-pool" # This is setting up gcp standard pool
  nodepool_size  = "n1-standard-2" # This tells gcp what kind of virtual machine to create
  nodepool_count = 1 # Kubernetes will create a minumum of 3 virtual machines to join to a cluster changing this adds 1 more VM per template IE setting to 2 will create 6 VM's
}