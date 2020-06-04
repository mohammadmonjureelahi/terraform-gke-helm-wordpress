# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A GKE PRIVATE CLUSTER IN GOOGLE CLOUD PLATFORM
# This is an example of how to use the gke-cluster module to deploy a private Kubernetes cluster in GCP.
# Load Balancer in front of it.
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  # The modules used in this example have been updated with 0.12 syntax, additionally we depend on a bug fixed in
  # version 0.12.7.
  required_version = ">= 0.12.7"
  
}

# ---------------------------------------------------------------------------------------------------------------------
# PREPARE PROVIDERS
# ---------------------------------------------------------------------------------------------------------------------

provider "google" {
  version = "~> 3.1.0"
  project = var.project
  region  = var.region
  //credentials = file("${var.path}/secrets-mohammad.json")
  credentials = var.gcp_json

  scopes = [
    # Default scopes
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
    "https://www.googleapis.com/auth/devstorage.full_control",

    # Required for google_client_openid_userinfo
    "https://www.googleapis.com/auth/userinfo.email",
  ]
}

provider "google-beta" {
  version = "~> 3.1.0"
  project = var.project
  region  = var.region
  //credentials = file("${var.path}/secrets-mohammad.json")
  credentials = var.gcp_json

  scopes = [
    # Default scopes
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
    "https://www.googleapis.com/auth/devstorage.full_control",

    # Required for google_client_openid_userinfo
    "https://www.googleapis.com/auth/userinfo.email",
  ]
}

# We use this data provider to expose an access token for communicating with the GKE cluster.
data "google_client_config" "client" {}

# Use this datasource to access the Terraform account's email for Kubernetes permissions.
data "google_client_openid_userinfo" "terraform_user" {}

provider "kubernetes" {
  version = "~> 1.7.0"

  load_config_file       = false
  host                   = data.template_file.gke_host_endpoint.rendered
  token                  = data.template_file.access_token.rendered
  cluster_ca_certificate = data.template_file.cluster_ca_certificate.rendered
}

provider "helm" {
  # Use provider with Helm 3.x support
  version = "~> 1.1.1"

  kubernetes {
    host                   = data.template_file.gke_host_endpoint.rendered
    token                  = data.template_file.access_token.rendered
    cluster_ca_certificate = data.template_file.cluster_ca_certificate.rendered
    load_config_file       = false
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A PRIVATE CLUSTER IN GOOGLE CLOUD PLATFORM
# ---------------------------------------------------------------------------------------------------------------------

module "gke_cluster" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "github.com/gruntwork-io/terraform-google-gke.git//modules/gke-cluster?ref=v0.2.0"
  source = "./modules/gke-cluster"

  name = var.cluster_name

  project  = var.project
  location = var.location
  network  = module.vpc_network.network

  # Deploy the cluster in the 'private' subnetwork, outbound internet access will be provided by NAT
  # See the network access tier table for full details:
  # https://github.com/gruntwork-io/terraform-google-network/tree/master/modules/vpc-network#access-tier
  subnetwork = module.vpc_network.private_subnetwork

  # When creating a private cluster, the 'master_ipv4_cidr_block' has to be defined and the size must be /28
  master_ipv4_cidr_block = var.master_ipv4_cidr_block

  # This setting will make the cluster private
  enable_private_nodes = "true"

  # To make testing easier, we keep the public endpoint available. In production, we highly recommend restricting access to only within the network boundary, requiring your users to use a bastion host or VPN.
  disable_public_endpoint = "false"

  # With a private cluster, it is highly recommended to restrict access to the cluster master
  # However, for testing purposes we will allow all inbound traffic.
  master_authorized_networks_config = [
    {
      cidr_blocks = [
        {
          cidr_block   = "0.0.0.0/0"
          display_name = "all-for-testing"
        },
      ]
    },
  ]

  cluster_secondary_range_name = module.vpc_network.private_subnetwork_secondary_range_name
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A NODE POOL
# ---------------------------------------------------------------------------------------------------------------------

resource "google_container_node_pool" "node_pool" {
  provider = google-beta

  name     = "main-pool"
  project  = var.project
  location = var.location
  cluster  = module.gke_cluster.name

  initial_node_count = "1"

  autoscaling {
    min_node_count = "1"
    max_node_count = "3"
    
    }
# Upgrading is required if we want to deply multiple helm chart or we want to upgrade or change as I found from trial and errors
  
  upgrade_settings {
    max_surge = "1"
    max_unavailable = "1"

  }

  management {
    auto_repair  = "true"
    auto_upgrade = "true"
  }

  node_config {
    image_type   = "COS"
    machine_type = "n1-standard-1"

    labels = {
      all-pools-example = "true"
    }

    # Add a private tag to the instances. See the network access tier table for full details:
    # https://github.com/gruntwork-io/terraform-google-network/tree/master/modules/vpc-network#access-tier
    tags = [
      module.vpc_network.private,
      "helm-example",
    ]

    disk_size_gb = "30"
    disk_type    = "pd-standard"
    preemptible  = false

    service_account = module.gke_service_account.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  lifecycle {
    ignore_changes = [initial_node_count]
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A CUSTOM SERVICE ACCOUNT TO USE WITH THE GKE CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

module "gke_service_account" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "github.com/gruntwork-io/terraform-google-gke.git//modules/gke-service-account?ref=v0.2.0"
  source = "./modules/gke-service-account"

  name        = var.cluster_service_account_name
  project     = var.project
  description = var.cluster_service_account_description
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A NETWORK TO DEPLOY THE CLUSTER TO
# ---------------------------------------------------------------------------------------------------------------------

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

module "vpc_network" {
#  source = "github.com/gruntwork-io/terraform-google-network.git//modules/vpc-network?ref=v0.4.0"
   source = "./modules/vpc-network"

  name_prefix = "${var.cluster_name}-network-${random_string.suffix.result}"
  project     = var.project
  region      = var.region

  cidr_block           = var.vpc_cidr_block
  secondary_cidr_block = var.vpc_secondary_cidr_block
}

# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE KUBECTL AND RBAC ROLE PERMISSIONS
# ---------------------------------------------------------------------------------------------------------------------

# configure kubectl with the credentials of the GKE cluster
# The null_resource resource implements the standard resource lifecycle but takes no further action
# If you need to run provisioners that aren't directly associated with a specific resource, you can associate them with a null_resource.
# Instances of null_resource are treated like normal resources, but they don't do anything. Like with any other
# resource, you can configure provisioners and connection details on a null_resource. You can also use its
# triggers argument and any meta-arguments to control exactly where in the dependency graph its provisioners will run.

resource "null_resource" "configure_kubectl" {
  provisioner "local-exec" {
    command = "gcloud beta container clusters get-credentials ${module.gke_cluster.name} --region ${var.region} --project ${var.project}"

    # Use environment variables to allow custom kubectl config paths
    environment = {
      KUBECONFIG = var.kubectl_config_path != "" ? var.kubectl_config_path : ""
    }
  }

  depends_on = [google_container_node_pool.node_pool]
}

resource "kubernetes_cluster_role_binding" "user" {
  metadata {
    name = "admin-user"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "cluster-admin"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "User"
    name      = data.google_client_openid_userinfo.terraform_user.email
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "Group"
    name      = "system:masters"
    api_group = "rbac.authorization.k8s.io"
  }
}

######### Below are regarding the vault and helm chart deployment #########
resource "kubernetes_namespace" "terravault" {
  metadata {
    name = "terravault"
  }
}

resource "google_storage_bucket" "vault_bucket" {
  name               = "${var.project}-vault-storage"
  project            = var.project
  location           = var.location
  force_destroy      = var.force_destroy_bucket
}

/*backend "gcs" {
      bucket        = "${google_storage_bucket.vault_bucket.name}"
  }*/

/*resource "google_service_account" "vault_service_account" {
  account_id   = "vault-admin"
  display_name = "Service account for vault"

}*/
resource "google_project_iam_member" "vault_iam_storage_role" {
  project = var.project
  role = "roles/storage.admin"
  //member = "serviceAccount:${google_service_account.vault_service_account.account_id}@${var.project}.iam.gserviceaccount.com"
  member = "serviceAccount:${module.gke_service_account.account_id}@${var.project}.iam.gserviceaccount.com"
}
resource "google_project_iam_member" "vault_iam_kms_role" {
  project = var.project
  role = "roles/cloudkms.admin"
  //member = "serviceAccount:${google_service_account.vault_service_account.account_id}@${var.project}.iam.gserviceaccount.com"
  member = "serviceAccount:${module.gke_service_account.account_id}@${var.project}.iam.gserviceaccount.com"
}
resource "google_service_account_key" "vault_account_key" {
  //service_account_id = google_service_account.vault_service_account.name
  service_account_id = module.gke_service_account.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}
resource "kubernetes_secret" "vault_credentials" {
  metadata {
    name = "vault-gcp-credentials"
    namespace = kubernetes_namespace.terravault.metadata.0.name
  }
  data = {
    "credentials.json" = base64decode(google_service_account_key.vault_account_key.private_key)
  }
}

/*resource "google_storage_bucket_iam_binding" "external_service_acc_binding" {
  //count  = var.use_external_service_account ? 1 : 0
  bucket = google_storage_bucket.vault_bucket.name
  role   = "roles/storage.objectAdmin"

  members = [
    "serviceAccount:${google_service_account.vault_service_account.account_id}@${var.project}.iam.gserviceaccount.com",
  ]
  

  depends_on = [
    google_storage_bucket.vault_bucket,
  
  ]
}*/

################## Above are for vault and helm chart ##########################



# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A SAMPLE CHART
# A chart repository is a location where packaged charts can be stored and shared. Define Bitnami Helm repository location,
# so Helm can install the nginx chart.
# ---------------------------------------------------------------------------------------------------------------------

# The below is added for the voult helm chart

resource "helm_release" "vault" {
  name        = "vault"
  repository  = "https://helm.releases.hashicorp.com"
  chart       = "vault"
  #version     = var.helm_version
  namespace   = kubernetes_namespace.terravault.metadata.0.name
  description = "HA vault cluster"
  
  set_string {
    name  = "server.extraVolumes[0].type"
    value = "secret"
  }
  set_string {
    name  = "server.extraVolumes[0].name"
    value = kubernetes_secret.vault_credentials.metadata.0.name
  }
  /*set_string {
    name  = "server.extraVolumes[0].type"
    value = "ConfigMap"
  }
  set_string {
    name  = "server.extraVolumes[0].name"
    value = "creds"
  }*/
  # set {
  #   name  = "server.extraVolumes[0]"
  #   value = "secret"
  # }
  # set {
  #   name  = "server.extraVolumes.  name"
  #   value = "creds"
  # }
  # set {
  #   name  = "server.extraVolumes[1]"
  #   value = "creds"
  # }
  set {
    name  = "server.extraEnvironmentVars.GOOGLE_REGION"
    value = "global"
  }
  set {
    name  = "server.extraEnvironmentVars.GOOGLE_PROJECT"
    value = var.project
  }
  set {
    name  = "server.extraEnvironmentVars.GOOGLE_APPLICATION_CREDENTIALS"
    value = "/vault/userconfig/${kubernetes_secret.vault_credentials.metadata.0.name}/credentials.json"
  }
  set {
    name  = "server.ha.enabled"
    value = "true"
  }
  set {
    name  = "server.ha.replicas"
    value = var.replicas
  }
  set {
    name = "server.ha.config"
    value = <<EOF
      listener "tcp" {
        tls_disable = 1
        address = "[::]:8200"
        cluster_address = "[::]:8201"
      }
      storage "gcs" {
        bucket        = "${google_storage_bucket.vault_bucket.name}"
        ha_enabled    = "true"
      }

      seal "gcpckms" {
        project     = "${var.project}"
        region      = "global"
        key_ring    = "vault_ring"
        crypto_key  = "vault_seal"
        credentials = "/vault/userconfig/${kubernetes_secret.vault_credentials.metadata.0.name}/credentials.json"
      }

      service_registration "kubernetes" {}
      EOF
  }

  set {
    name  = "server.shareProcessNamespace"
    value = "true"
  }

  set {
    name  = "ui.enabled"
    value = var.vault_ui
  }

  set {
    name  = "ui.serviceType"
    value = "LoadBalancer"
  }

  set {
  name  = "server.extraContainers[0].name"
  value = "vault-init"
  }
  set {
    name  = "server.extraContainers[0].image"
    value = "gcr.io/hightowerlabs/vault-init"
  }
  set {
    name  = "server.extraContainers[0].env[0].name"
    value = "GCS_BUCKET_NAME"
  }
  set {
    name  = "server.extraContainers[0].env[0].value"
    value = google_storage_bucket.vault_bucket.name
  }
  set {
    name  = "server.extraContainers[0].env[1].name"
    value = "KMS_KEY_ID"
  }
  set {
    name  = "server.extraContainers[0].env[1].value"
    value = "projects/sasp-vault/locations/global/vault_ring/vault_seal"
  } 

}


/*resource "helm_release" "vault" {
  depends_on = [google_container_node_pool.node_pool]

  repository = "https://github.com/hashicorp/vault-helm"
#  name       = "nginx"
#  chart      = "nginx"
   name       = "vault"
   chart      = "vault" 
}*/
/*resource "helm_release" "wordpress" {
  depends_on = [google_container_node_pool.node_pool]

  repository = "https://charts.bitnami.com/bitnami"
#  name       = "nginx"
#  chart      = "nginx"
   name       = "wordpress"
   chart      = "wordpress" 
}


resource "helm_release" "apache" {
  depends_on = [google_container_node_pool.node_pool]

  repository = "https://charts.bitnami.com/bitnami"
#  name       = "nginx"
#  chart      = "nginx"
   name       = "apache"
   chart      = "apache" 
}

resource "helm_release" "mysql" {
  depends_on = [google_container_node_pool.node_pool]

  repository = "https://charts.bitnami.com/bitnami"
#  name       = "nginx"
#  chart      = "nginx"
   name       = "mysql"
   chart      = "mysql" 
} */

/*resource "helm_release" "dokuwiki" {
  depends_on = [google_container_node_pool.node_pool]

  repository = "https://charts.bitnami.com/bitnami"
#  name       = "nginx"
#  chart      = "nginx"
   name       = "dokuwiki"
   chart      = "dokuwiki" 
}

resource "helm_release" "owncloud" {
  depends_on = [google_container_node_pool.node_pool]

  repository = "https://charts.bitnami.com/bitnami"
#  name       = "nginx"
#  chart      = "nginx"
   name       = "owncloud"
   chart      = "owncloud" 
}*/

/*resource "helm_release" "postgresql-ha" {
  depends_on = [google_container_node_pool.node_pool]

  repository = "https://charts.bitnami.com/bitnami"
#  name       = "nginx"
#  chart      = "nginx"
   name       = "postgresql-ha"
   chart      = "postgresql-ha" 
} */

/*resource "helm_release" "kubernetes-dashboard" {
  depends_on = [google_container_node_pool.node_pool]

  repository = "https://kubernetes-charts.storage.googleapis.com"
#  name       = "nginx"
#  chart      = "nginx"
   name       = "airflow"
   chart      = "airflow" 
}*/

/*resource "helm_release" "kubernetes-dashboard" {
  depends_on = [google_container_node_pool.node_pool]

  repository = "https://helm.nginx.com/stable"
#  name       = "nginx"
#  chart      = "nginx"
   name       = "nginx-ingress"
   chart      = "nginx-ingress" 
} */
# ---------------------------------------------------------------------------------------------------------------------
# WORKAROUNDS
# ---------------------------------------------------------------------------------------------------------------------

# This is a workaround for the Kubernetes and Helm providers as Terraform doesn't currently support passing in module
# outputs to providers directly.
data "template_file" "gke_host_endpoint" {
  template = module.gke_cluster.endpoint
}

data "template_file" "access_token" {
  template = data.google_client_config.client.access_token
}

data "template_file" "cluster_ca_certificate" {
  template = module.gke_cluster.cluster_ca_certificate
}
