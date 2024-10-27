# TERRAGRUNT CONFIGURATION
#
# Global configuration for all the environments


locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Unpack variables for easy access
  project_id                  = local.environment_vars.locals.project_id
  region                      = local.environment_vars.locals.region
  zone1                       = local.environment_vars.locals.zone1

  service_account             = local.environment_vars.locals.service_account
  bucket_name                 = local.environment_vars.locals.bucket_name

  terraform_version           = local.environment_vars.locals.terraform_version
  provider_google_version     = local.environment_vars.locals.provider_google_version
  provider_kubernetes_version = local.environment_vars.locals.provider_kubernetes_version
}


# Configure Terragrunt to automatically store tfstate files in an GCS bucket.
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

# Generate Terraform and Provider versions
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

# Generate providers
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
