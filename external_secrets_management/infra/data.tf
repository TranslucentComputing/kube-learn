/**
 * Data resource for external secrets configuration.
 */

# Retrieve access token
data "google_service_account_access_token" "default" {
  target_service_account = var.impersonate_account
  scopes                 = ["cloud-platform"]
  lifetime               = "660s"
}

data "google_container_cluster" "cluster" {
  project  = var.project_id
  name     = var.cluster_name
  location = var.cluster_location
}

# Retrieve GKE Management from TF state
data "terraform_remote_state" "gke_man" {
  backend = "gcs"
  config = {
    bucket = var.data_gke_man_bucket
    prefix = var.data_gke_man_bucket_prefix
  }
}

# Retrieve GKE Management deployed after Vault from TF state
data "terraform_remote_state" "gke_man_after" {
  backend = "gcs"
  config = {
    bucket = var.data_gke_man_after_bucket
    prefix = var.data_gke_man_after_bucket_prefix
  }
}

# Retrieve Vault from TF state
data "terraform_remote_state" "vault" {
  backend = "gcs"
  config = {
    bucket = var.data_vault_bucket
    prefix = var.data_vault_bucket_prefix
  }
}

# Retrieve Vault config from TF state
data "terraform_remote_state" "vault_config" {
  backend = "gcs"
  config = {
    bucket = var.data_vault_config_bucket
    prefix = var.data_vault_config_bucket_prefix
  }
}

# Retrieve Database SSO config from TF state
data "terraform_remote_state" "database_sso" {
  count   = var.configure_sso_database ? 1 : 0
  backend = "gcs"
  config = {
    bucket = var.data_database_sso_bucket
    prefix = var.data_database_sso_bucket_prefix
  }
}

#Retrieve Keycloak management from TF state
data "terraform_remote_state" "kc_man" {
  count   = var.configure_keycloak ? 1 : 0
  backend = "gcs"
  config = {
    bucket = var.data_kc_man_bucket
    prefix = var.data_kc_man_bucket_prefix
  }
}

#Retrieve Keycloak from TF state
data "terraform_remote_state" "kc" {
  count   = var.configure_keycloak ? 1 : 0
  backend = "gcs"
  config = {
    bucket = var.data_kc_bucket
    prefix = var.data_kc_bucket_prefix
  }
}
