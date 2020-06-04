output "email" {
  # This may seem redundant with the `name` input, but it serves an important
  # purpose. Terraform won't establish a dependency graph without this to interpolate on.
  description = "The email address of the custom service account."
  value       = google_service_account.service_account.email
}

output "account_id" {
  value       = google_service_account.service_account.account_id
}

output "name" {
  value       = google_service_account.service_account.name
}
