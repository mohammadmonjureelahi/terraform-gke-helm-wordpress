variable "gcp_json" {
  description = "Base64 encoded json from terraform-cloud gcp account"
}

variable "cluster_project_id" {
  description = "The ID of the project in which the resource belongs. If it is not provided, the provider project is used"
}

variable "cluster_region" {
  description = "The default region to manage resources in. If another region is specified on a regional resource, it will take precedence"
}

variable "cluster_zone" {
  description = "The default zone to manage resources in. Generally, this zone should be within the default region you specified. If another zone is specified on a zonal resource, it will take precedence"
}

variable "environment" {
  description = "Namespace of release"
}

variable "helm_version" {
  description = "Version of vault release without v ie: github release v0.5.0 would be 0.5.0"
}

variable "replicas" {
  description = "Number of HA vault replicas to create"
  default = "3"
}

variable "force_destroy_bucket" {
  default = false
  description = "(Optional, Default: false) When deleting a bucket, this boolean option will delete all contained objects. If you try to delete a bucket that contains objects, Terraform will fail that run."
}

variable "bucket_name" {
  default = "vault-bucket"
  description = "Name of the GCP bucket"
}

variable "allow_http" {
  description = "Allow http access to vault"
  default = "true"
}

variable "vault_ui" {
  description = "true/false Vault webUI"
  default = "true"
}

variable "tls_disable" {
  default = true
}
