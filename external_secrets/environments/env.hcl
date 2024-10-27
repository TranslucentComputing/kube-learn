# Set common variables for the environment.
# This is automatically pulled in in the root terragrunt.hcl configuration to
# feed forward to the child modules.

locals {
  # GCP config
  project_id        = "change-me"                    # Replace with your actual GCP project ID
  region            = "change-me"                    # Replace with the target region (e.g., "northamerica-northeast2")
  short_region      = "change-me"                    # Short region identifier (e.g., "na-ne2")
  zone1             = "change-me"                    # Availability zone (e.g., "northamerica-northeast2-a")
  short_zone1       = "change-me"                    # Short zone identifier (e.g., "na-ne2-a")

  # Service Account to be impersonated
  service_account   = "change-me@change-me.iam.gserviceaccount.com"  # Replace with your service account email

  # Variables to create GCS Bucket within GCP
  bucket_name       = "change-me"                    # Replace with your GCS bucket name for Terraform state

  # Terraform Version
  terraform_version = ">=1.6"                        # Specify minimum Terraform version (if needed)

  # Provider Versions
  provider_google_version     = "5.10.0"             # Google provider version
  provider_kubernetes_version = "2.24.0"             # Kubernetes provider version
  provider_helm_version       = "2.12.1"             # Helm provider version
}
