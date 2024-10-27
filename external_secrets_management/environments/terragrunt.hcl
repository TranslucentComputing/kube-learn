# TERRAGRUNT CONFIGURATION
#
# Global configuration for all environments in external secrets management.
# This file provides foundational settings and configurations that are shared
# across different environments, such as remote state, provider settings,
# and Terraform version constraints.


locals {
  # Load environment-level variables from env.hcl in a parent directory.
  # These variables contain project-specific details for the Google Cloud setup.
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Unpack and define local variables for easy access in this configuration.
  project_id                  = local.environment_vars.locals.project_id
  region                      = local.environment_vars.locals.region
  zone1                       = local.environment_vars.locals.zone1

  service_account             = local.environment_vars.locals.service_account
  bucket_name                 = local.environment_vars.locals.bucket_name

  terraform_version           = local.environment_vars.locals.terraform_version
  provider_google_version     = local.environment_vars.locals.provider_google_version
  provider_kubernetes_version = local.environment_vars.locals.provider_kubernetes_version
}


# Configure remote state management using Google Cloud Storage (GCS).
# This setup stores Terraform state files remotely in a GCS bucket, allowing for
# centralized state management and collaboration across team members.
remote_state {
  backend = "gcs"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    project                     = "${local.project_id}"
    location                    = "${local.region}"
    bucket                      = "${local.bucket_name}"
    prefix                      = "gke/security/external_secrets/management/${path_relative_to_include()}"
    skip_bucket_creation        = true
    impersonate_service_account = "${local.service_account}"
  }
}

# Generate a Terraform version file specifying required providers and versions.
# This configuration ensures compatibility by enforcing specific provider versions.
generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = "${local.terraform_version}"

  required_providers {
    google = {
      source = "hashicorp/google"
      version = "${local.provider_google_version}"
    }
    google-beta = {
      source = "hashicorp/google-beta"
      version = "${local.provider_google_version}"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "${local.provider_kubernetes_version}"
    }
  }
}
EOF
}

# Generate provider configurations for Google and Kubernetes.
# This includes settings for the Google provider (both standard and beta)
# and the Kubernetes provider for interacting with the GKE cluster.
generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
provider "google" {
  project     = "${local.project_id}"
  region      = "${local.region}"
  zone        = "${local.zone1}"
  impersonate_service_account = "${local.service_account}"
}

provider "google-beta" {
  project     = "${local.project_id}"
  region      = "${local.region}"
  zone        = "${local.zone1}"
  impersonate_service_account = "${local.service_account}"
}

provider "kubernetes" {
  host  = "https://$${data.google_container_cluster.cluster.private_cluster_config[0].private_endpoint}"
  token = data.google_service_account_access_token.default.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.cluster.master_auth[0].cluster_ca_certificate,
  )
}
EOF
}
