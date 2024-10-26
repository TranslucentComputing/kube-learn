# TERRAGRUNT CONFIGURATION
#
# Configuration for the prod environment.
#
# Copyright 2023 Translucent Computing Inc.


# Include configurations that are common used across multiple environments.
include "root" {
  path = find_in_parent_folders()
}

# Include the infra
terraform {
  source = "${get_terragrunt_dir()}/../../infra"
}

locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Unpack variables for easy access
  project_id       = local.environment_vars.locals.project_id
  region           = local.environment_vars.locals.region
  short_region     = local.environment_vars.locals.short_region
  zone1            = local.environment_vars.locals.zone1
  service_account  = local.environment_vars.locals.service_account

  # This will get the directory name
  environment = basename(path_relative_to_include())
}

# Inputs for infra
inputs = {
  environment         = local.environment
  project_id          = local.project_id
  region              = local.region
  short_region        = local.short_region
  impersonate_account = local.service_account
  cluster_name        = "tc-tekstack-kps-${local.environment}-cluster"
  cluster_location    = local.zone1

  # TF state for GKE management
  data_gke_man_bucket        = "tc-tekstack-kps-terraform-state-bucket"
  data_gke_man_bucket_prefix = "gke/management/${local.environment}/initial"

  # TF state for GKE management after Vault deployment
  data_gke_man_after_bucket        = "tc-tekstack-kps-terraform-state-bucket"
  data_gke_man_after_bucket_prefix = "gke/management/${local.environment}/after_security"

  # Vault TF state config
  data_vault_bucket        = "tc-tekstack-kps-terraform-state-bucket"
  data_vault_bucket_prefix = "gke/security/vault/${local.environment}"

  # Vault config TF state config
  data_vault_config_bucket        = "tc-tekstack-kps-terraform-state-bucket"
  data_vault_config_bucket_prefix = "gke/security/vault/${local.environment}/config"

  data_database_sso_bucket        = "tc-tekstack-kps-terraform-state-bucket"
  data_database_sso_bucket_prefix = "gke/security/postgresql/${local.environment}"

  # TF state for Keycloak management
  data_kc_man_bucket = "tc-tekstack-kps-terraform-state-bucket"
  data_kc_man_bucket_prefix = "gke/security/keycloak/management/${local.environment}/config"

  # TF state for Keycloak
  data_kc_bucket = "tc-tekstack-kps-terraform-state-bucket"
  data_kc_bucket_prefix = "gke/security/keycloak/${local.environment}"

  vault_database_sso_tls_secret_name = "database-sso-tls"
  vault_database_sso_tls_ttl = "2d"

  vault_keycloak_database_secret_name = "keycloak-database-data"
  vault_keycloak_admin_secret_name    = "keycloak-admin-user"
  vault_keycloak_metrics_secret_name  = "keycloak-metrics-user"

  vault_grafana_admin_secret_name   = "grafana-admin-user"
  grafana_admin_secret_user_value   = "kubert-admin"
  grafana_admin_secret_user_key     = "admin-user"
  grafana_admin_secret_password_key = "admin-password"

  alertmanager_secret_name = "alertmanager-oauth"
  headlamp_secret_name = "headlamp-kc-client"

  vault_lobechat_secret_name = "lobechat-credentials"

  serpapi_api_key = "36b1dacee6c8d0d6423d1d457682d55365b9f018"

  opencost_secret_name = "opencost-oauth"

  configure_sso_database = true # Default to flas, change to true once the SSO database is deployed
  configure_keycloak = true # Default to false, change to true after keycloak database is deployed

  ollama_secret_name = "ollama-oauth"
}
