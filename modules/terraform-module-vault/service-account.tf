# This file contains all the nessesary service account permissions that are required for vault to comminucate with gcp buckets and kms key

resource "google_service_account" "vault_service_account" {
  account_id   = "vault-account"
  display_name = "Service account for vault"
}

resource "google_project_iam_member" "vault_iam_storage_role" {
  project = var.cluster_project_id
  role = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.vault_service_account.account_id}@${var.cluster_project_id}.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "vault_iam_kms_role" {
  project = var.cluster_project_id
  role = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member = "serviceAccount:${google_service_account.vault_service_account.account_id}@${var.cluster_project_id}.iam.gserviceaccount.com"
}

resource "google_service_account_key" "vault_account_key" {
  service_account_id = google_service_account.vault_service_account.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "kubernetes_secret" "vault_credentials" {
  metadata {
    name = "vault-gcp-credentials"
    namespace = var.environment
  }
  data = {
    "credentials.json" = base64decode(google_service_account_key.vault_account_key.private_key)
  }
}