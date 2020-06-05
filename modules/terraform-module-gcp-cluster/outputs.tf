output "cluster_username" {
  value = google_container_cluster.gcp_cluster.master_auth.0.username
}

output "cluster_password" {
  value = google_container_cluster.gcp_cluster.master_auth.0.password
}

output "endpoint" {
  value = google_container_cluster.gcp_cluster.endpoint
}

output "instance_group_urls" {
  value = google_container_cluster.gcp_cluster.instance_group_urls
}

output "node_config" {
  value = google_container_cluster.gcp_cluster.node_config
}

output "node_pools" {
  value = google_container_cluster.gcp_cluster.node_pool
}

output "client_certificate" {
  value = google_container_cluster.gcp_cluster.master_auth.0.client_certificate
}

output "client_key" {
  value = google_container_cluster.gcp_cluster.master_auth.0.client_key
}

output "cluster_ca_certificate" {
  value = google_container_cluster.gcp_cluster.master_auth.0.cluster_ca_certificate
}

output "token" {
  value = data.google_client_config.default.access_token
}
