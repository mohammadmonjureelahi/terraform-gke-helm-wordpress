resource "helm_release" "vault" {
  name        = "vault"
  repository  = "https://helm.releases.hashicorp.com"
  chart       = "vault"
  version     = var.helm_version
  namespace   = var.environment
  description = "HA vault cluster"

  set {
    name  = "server.ha.enabled"
    value = "true"
  }

  set {
    name  = "server.ha.replicas"
    value = var.replicas
  }

# This is disabled for you, We are activly working on getting tls enabled.
  set {
    name  = "global.tlsDisable"
    value = var.tls_disable
  }

  set {
    name  = "server.ha.config"
    value = <<EOF
      listener "tcp" {
        tls_disable = 1
        address = "[::]:8200"
        cluster_address = "[::]:8201"
      }

      storage "gcs" {
        bucket      = "${google_storage_bucket.vault_bucket.name}"
        ha_enabled  = "true"
      }

      seal "gcpckms" {
        project     = "${var.cluster_project_id}"
        region      = "global"
        key_ring    = "vault_ring"
        crypto_key  = "vault_seal"
        credentials = "/vault/userconfig/${kubernetes_secret.vault_credentials.metadata.0.name}/credentials.json"
      }

      service_registration "kubernetes" {}
      EOF
  }

  set {
    name  = "server.extraEnvironmentVars.GOOGLE_REGION"
    value = "global"
  }

  set {
    name  = "server.extraEnvironmentVars.GOOGLE_PROJECT"
    value = var.cluster_project_id
  }

  set {
    name  = "server.extraEnvironmentVars.GOOGLE_APPLICATION_CREDENTIALS"
    value = "/vault/userconfig/${kubernetes_secret.vault_credentials.metadata.0.name}/credentials.json"
  }

  # set {
  #   name  = "server.extraEnvironmentVars.VAULT_CACERT"
  #   value = "/vault/userconfig/vault-server-tls/vault.ca"
  # }

  set {
    name  = "server.extraVolumes[0].type"
    value = "secret"
  }

  set {
    name  = "server.extraVolumes[0].name"
    value = kubernetes_secret.vault_credentials.metadata.0.name
  }

  # set {
  #   name  = "server.extraVolumes[1].type"
  #   value = "secret"
  # }

  # set {
  #   name  = "server.extraVolumes[1].name"
  #   value = "vault-server-tls"
  # }

  set {
    name  = "ui.enabled"
    value = var.vault_ui
  }

  set {
    name  = "ui.serviceType"
    value = "LoadBalancer"
  }

# These are currently commented for you because we are still activly working on getting the init container to work
  # set {
  #   name  = "server.extraContainers[0].name"
  #   value = "vault-init"
  # }

  # set {
  #   name  = "server.extraContainers[0].image"
  #   value = "sethvargo/vault-init"
  # }

  # set {
  #   name  = "server.extraContainers[0].env[0].name"
  #   value = "GCS_BUCKET_NAME"
  # }

  # set {
  #   name  = "server.extraContainers[0].env[0].value"
  #   value = google_storage_bucket.vault_bucket.name
  # }

  # set {
  #   name  = "server.extraContainers[0].env[1].name"
  #   value = "KMS_KEY_ID"
  # }

  # set {
  #   name  = "server.extraContainers[0].env[1].value"
  #   value = "projects/sasp-vault/locations/global/vault_ring/vault_seal"
  # }

  # set {
  #   name  = "server.extraContainers[0].env[2].name"
  #   value = "VAULT_SKIP_VERIFY"
  # }

  # set {
  #   name  = "server.extraContainers[0].env[2].value"
  #   value = "true"
  # }

  set {
    name  = "server.shareProcessNamespace"
    value = "true"
  }
}
