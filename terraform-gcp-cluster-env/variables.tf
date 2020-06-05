variable "cluster_gcp_json" {
  description = "Base64 encoded gcp json from manually created account in gcp with project editor and kubernetes engine admin IAM"
}

variable "vault_version" {
  default = "0.5.0"
}

variable "project_id" {
  description = "ID of the project you want to deploy too"
}