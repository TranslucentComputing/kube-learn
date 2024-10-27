# TERRAGRUNT CONFIGURATION
#
# Configuration for the production environment for the external_secrets tool.


# Include root-level configurations that are shared across multiple environments.
# This typically includes common variables and configurations that are set in a parent directory.
include "root" {
  path = find_in_parent_folders()
}

# Include the Terraform infrastructure code from the infra directory
# The source path is relative to the current directory and points to the main Terraform configuration.
terraform {
  source = "${get_terragrunt_dir()}/../../infra"
}

# Define local variables to simplify referencing environment variables and configurations
locals {
  # Load environment-level variables from the env.hcl file located in a parent directory.
  # These variables provide settings such as project_id, region, and service account.
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Unpack the loaded environment variables for easier access in this configuration.
  project_id       = local.environment_vars.locals.project_id
  region           = local.environment_vars.locals.region
  short_region     = local.environment_vars.locals.short_region
  zone1            = local.environment_vars.locals.zone1
  service_account  = local.environment_vars.locals.service_account

  # Define the environment based on the directory name for the current configuration.
  # This helps in dynamically setting up environment-specific resources.
  environment = basename(path_relative_to_include())
}

# Define inputs to be passed to the Terraform infrastructure module
inputs = {
  environment         = local.environment      # Specifies the environment (e.g., prod)
  project_id          = local.project_id       # Google Cloud project ID
  region              = local.region           # Google Cloud region
  short_region        = local.short_region     # Shortened region identifier
  impersonate_account = local.service_account  # Service account to impersonate for GCP access
  cluster_name        = "change-me-${local.environment}-cluster" # Cluster name (use "change-me" as placeholder)
  cluster_location    = local.zone1            # GCP zone for the cluster

  # Google Cloud Storage (GCS) bucket settings for GKE management state
  data_gke_man_bucket        = "change-me"     # GCS bucket name for storing GKE management state
  data_gke_man_bucket_prefix = "gke/management/${local.environment}/initial"  # GCS bucket prefix for GKE state files

  # Prom stack TF state config
  data_prom_stack_bucket          = "change-me" # GCS bucket for storing Prometheus stack state
  data_prom_stack_bucket_prefix = "gke/observability/prometheus-stack/${local.environment}" # Prefix for Prometheus stack state files

  # Helm chart settings for External Secrets
  chart_version = "0.10.5"                 # Version of the External Secrets Helm chart
  chart_release_name = "external-secrets"  # Release name for the External Secrets Helm chart deployment

  # Resource requests and limits for the External Secrets controller
  resources = {
    requests = {
      cpu    = "65m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "65m"
      memory = "128Mi"
    }
  }

  # Resource requests and limits for the Webhook component
  webhook_resources = {
    requests = {
      cpu    = "55m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "55m"
      memory = "128Mi"
    }
  }

  # Certificate configuration settings for the External Secrets service
  cert_subject = {
    "organizations" = [
      "Your company - change-me"
    ]
    "organizationalUnits": [
      "Busines Unit - change-me"
    ]
  }

  # Certificate duration and renewal settings
  cert_duration = "8760h0m0s" # 365 days
  cert_renew    = "70080m0s"  # 293 days

  # Replica counts for External Secrets components
  replica_count         = 1
  replica_count_webhook = 1

  enable_metrics = true  # Default to false, change to true after observability tools are deployed
}
