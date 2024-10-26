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

  # Prom stack TF state config
  data_prom_stack_bucket          = "tc-tekstack-kps-terraform-state-bucket"
  data_prom_stack_bucket_prefix = "gke/observability/prometheus-stack/${local.environment}"

  chart_version = "0.9.20"
  chart_release_name = "external-secrets"

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

  cert_subject = {
    "organizations" = [
      "Translucent Computing Inc"
    ]
    "organizationalUnits": [
      "TEKStack",
      "Kubert"
    ]
  }

  cert_duration = "8760h0m0s" # 365 days
  cert_renew    = "70080m0s"  # 293 days

  replica_count         = 1
  replica_count_webhook = 1

  enable_metrics = true  # Default to false, change to true after observability tools are deployed
}
