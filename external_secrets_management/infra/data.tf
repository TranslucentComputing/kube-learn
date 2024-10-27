/**
 * Data resources for external secrets management configuration.
 * These data sources retrieve essential information from Google Cloud and
 * remote Terraform state files for configuring and managing the external secrets
 * and associated security components within a GKE environment.
 */

# Retrieve access token# Retrieve an access token for the specified service account.
# This token is used to authenticate requests to Google Cloud services with the required scope.
data "google_service_account_access_token" "default" {
  target_service_account = var.impersonate_account
  scopes                 = ["cloud-platform"]
  lifetime               = "660s"
}

# Retrieve information about the GKE cluster.
# This data source provides cluster details such as endpoint and authentication certificates,
# necessary for securely connecting to and managing the cluster.
data "google_container_cluster" "cluster" {
  project  = var.project_id
  name     = var.cluster_name
  location = var.cluster_location
}

# Retrieve the initial GKE management state from a Terraform remote state file in Google Cloud Storage (GCS).
# This state contains information on initial configurations for the GKE environment.
data "terraform_remote_state" "gke_man" {
  backend = "gcs"
  config = {
    bucket = var.data_gke_man_bucket
    prefix = var.data_gke_man_bucket_prefix
  }
}

# Retrieve the updated GKE management state from a Terraform remote state file in GCS.
# This state reflects configurations after Vault and additional security settings have been applied.
data "terraform_remote_state" "gke_man_after" {
  backend = "gcs"
  config = {
    bucket = var.data_gke_man_after_bucket
    prefix = var.data_gke_man_after_bucket_prefix
  }
}

# Retrieve Vault configuration from a Terraform remote state file in GCS.
# This state provides information necessary for interacting with Vault, such as paths and secrets configuration.
data "terraform_remote_state" "vault" {
  backend = "gcs"
  config = {
    bucket = var.data_vault_bucket
    prefix = var.data_vault_bucket_prefix
  }
}

# Retrieve Vault configuration details from a separate Terraform remote state file.
# This configuration is used for specific Vault setup and management tasks, including secret storage.
data "terraform_remote_state" "vault_config" {
  backend = "gcs"
  config = {
    bucket = var.data_vault_config_bucket
    prefix = var.data_vault_config_bucket_prefix
  }
}

# Retrieve the Single Sign-On (SSO) database configuration from a Terraform remote state file in GCS.
# This state provides the necessary configuration for SSO integration in the Kubernetes environment.
data "terraform_remote_state" "database_sso" {
  count   = var.configure_sso_database ? 1 : 0
  backend = "gcs"
  config = {
    bucket = var.data_database_sso_bucket
    prefix = var.data_database_sso_bucket_prefix
  }
}

# Retrieve Keycloak management configuration from a Terraform remote state file in GCS.
# This state includes configuration details for managing Keycloak within the environment.
data "terraform_remote_state" "kc_man" {
  count   = var.configure_keycloak ? 1 : 0
  backend = "gcs"
  config = {
    bucket = var.data_kc_man_bucket
    prefix = var.data_kc_man_bucket_prefix
  }
}

# Retrieve Keycloak configuration from a separate Terraform remote state file in GCS.
# This configuration is essential for deploying Keycloak and integrating it with the external secrets.
data "terraform_remote_state" "kc" {
  count   = var.configure_keycloak ? 1 : 0
  backend = "gcs"
  config = {
    bucket = var.data_kc_bucket
    prefix = var.data_kc_bucket_prefix
  }
}
