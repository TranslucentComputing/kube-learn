# TERRAGRUNT CONFIGURATION
#
# Configuration for the prod environment of external secrets management.
# This file includes environment-specific variables and inputs for managing
# secrets-related resources across the GKE environment.

# Include root-level configurations shared across multiple environments.
# This typically contains global settings and common configuration files.
include "root" {
  path = find_in_parent_folders()
}

# Specify the source for the Terraform infrastructure code in the infra directory.
# The path is relative to the current directory and points to the shared infrastructure code.
terraform {
  source = "${get_terragrunt_dir()}/../../infra"
}

# Define local variables for this environment
locals {
 # Load common environment-level variables from `env.hcl` in the parent directory.
  # These include project settings and service account details.
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Unpack environment variables for easier access within this configuration.
  project_id       = local.environment_vars.locals.project_id                  # Google Cloud project ID
  region           = local.environment_vars.locals.region                      # Google Cloud region
  short_region     = local.environment_vars.locals.short_region                # Shortened region identifier
  zone1            = local.environment_vars.locals.zone1                       # Default zone for Google Cloud resources
  service_account  = local.environment_vars.locals.service_account             # Service account for GCP impersonation

  # Define the environment based on the directory name for dynamically setting environment-specific resources.
  environment = basename(path_relative_to_include())
}

# Define inputs to be passed to the Terraform infrastructure module
inputs = {
  # Environment-specific variables
  environment         = local.environment
  project_id          = local.project_id
  region              = local.region
  short_region        = local.short_region
  impersonate_account = local.service_account
  cluster_name        = "change-me-${local.environment}-cluster"
  cluster_location    = local.zone1

  # GKE management state storage in Google Cloud Storage (GCS)
  data_gke_man_bucket        = "change-me" # GCS bucket for GKE management Terraform state
  data_gke_man_bucket_prefix = "gke/management/${local.environment}/initial"

  # GKE management state after deploying Vault
  data_gke_man_after_bucket        = "change-me" # GCS bucket for GKE management state after security configurations
  data_gke_man_after_bucket_prefix = "gke/management/${local.environment}/after_security"

   # Vault configuration state storage
  data_vault_bucket        = "change-me" # GCS bucket for Vault deployment Terraform state
  data_vault_bucket_prefix = "gke/security/vault/${local.environment}"

  # Vault config TF state config
  data_vault_config_bucket        = "change-me" # GCS bucket for Vault configuration state
  data_vault_config_bucket_prefix = "gke/security/vault/${local.environment}/config"

  # Database SSO state storage
  data_database_sso_bucket        = "change-me" # GCS bucket for database SSO Terraform state
  data_database_sso_bucket_prefix = "gke/security/postgresql/${local.environment}"

  # TF state for Keycloak management
  data_kc_man_bucket = "change-me" # GCS bucket for Keycloak management state
  data_kc_man_bucket_prefix = "gke/security/keycloak/management/${local.environment}/config"

  # TF state for Keycloak
  data_kc_bucket = "change-me" # GCS bucket for Keycloak Terraform state
  data_kc_bucket_prefix = "gke/security/keycloak/${local.environment}"

  # Vault secrets and TLS configuration
  vault_database_sso_tls_secret_name = "database-sso-tls"
  vault_database_sso_tls_ttl = "2d"

  # Keycloak secrets in Vault
  vault_keycloak_database_secret_name = "keycloak-database-data"
  vault_keycloak_admin_secret_name    = "keycloak-admin-user"
  vault_keycloak_metrics_secret_name  = "keycloak-metrics-user"

  # Grafana admin credentials in Vault
  vault_grafana_admin_secret_name   = "grafana-admin-user"
  grafana_admin_secret_user_value   = "kubert-admin"
  grafana_admin_secret_user_key     = "admin-user"
  grafana_admin_secret_password_key = "admin-password"

  # OAuth secrets
  alertmanager_secret_name = "alertmanager-oauth"
  opencost_secret_name = "opencost-oauth"

  # Lobechat
  vault_lobechat_secret_name = "lobechat-credentials"

  # Ollama
  ollama_secret_name = "ollama-oauth"

  configure_sso_database = true # Default to flas, change to true once the SSO database is deployed
  configure_keycloak = true # Default to false, change to true after keycloak database is deployed
}
