# Set common variables for the environment.
# This is automatically pulled in in the root terragrunt.hcl configuration to
# feed forward to the child modules.

locals {
  # GCP config
  project_id="tcinc-dev"
  region="northamerica-northeast2"
  short_region="na-ne2"
  zone1="northamerica-northeast2-a"
  short_zone1="na-ne2-a"

  # Service Account to be impersonated
  service_account="tc-tekstack-kps-priv-gke-sa@tcinc-dev.iam.gserviceaccount.com"

  # Variables to create GCS Bucket within GCP
  bucket_name="tc-tekstack-kps-terraform-state-bucket"

  # Terraform Version
  terraform_version = ">=1.6"

  # Provider Version
  provider_google_version     = "5.10.0"
  provider_kubernetes_version = "2.24.0"
}
