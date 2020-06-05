variable "gcp_json" {
  default = ""
}

variable "master_username" {}

variable "master_password" {}

variable "cluster_project_id" {}

variable "cluster_name" {}

variable "cluster_region" {}

variable "cluster_zone" {}

variable "nodepool_name" {}

variable "nodepool_size" {}

variable "nodepool_count" {}

variable "nodepool_preemptible" {
  default = false
}
