variable "cluster_gcp_json" {
  description = "Base64 encoded gcp json from manually created account in gcp with project editor and kubernetes engine admin IAM"
}

variable "master_password" {
  description = "This is a password so terraform can comminucate with kubernetes, Can be any random string we use a 16 character and base64 encode it"
}

variable "project_id" {
  description = "ID of the project you want to deploy too"
}

variable "kubernetes_cluster_name" {
  description = "Name of the kubernetes cluster to create in gcp"
  default = "kubernetes-cluster"
}