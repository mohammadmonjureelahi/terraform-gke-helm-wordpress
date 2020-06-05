output "cluster_endpoint" {
  value = module.gcp_cluster.endpoint
}

output "cluster_token" {
  value = module.gcp_cluster.token
}

output "cluster_certificate" {
  value = module.gcp_cluster.cluster_ca_certificate
}
