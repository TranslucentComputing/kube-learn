/**
 * Data resources for external secrets deployment.
 * These data sources retrieve essential information from Google Cloud and Terraform
 * for configuring and managing the external secrets tool within a GKE cluster.
 */

# Retrieve an access token for the Google service account specified in `var.impersonate_account`.
# This access token will be used to authenticate requests with the specified scope.
data "google_service_account_access_token" "default" {
  target_service_account = var.impersonate_account
  scopes                 = ["cloud-platform"]
  lifetime               = "660s"                  # Token lifetime of 660 seconds (11 minutes)
}

# Retrieve information about the GKE cluster.
# This data resource fetches details such as the cluster endpoint, authentication certificates,
# and other metadata needed for connecting and deploying to the cluster.
data "google_container_cluster" "cluster" {
  project  = var.project_id
  name     = var.cluster_name
  location = var.cluster_location
}

# Retrieve the state of the GKE management resources from a Terraform state file stored in a GCS bucket.
# This remote state data is used to access information about resources managed elsewhere, allowing
# for cross-module references and dependencies.
data "terraform_remote_state" "gke_man" {
  backend = "gcs"
  config = {
    bucket = var.data_gke_man_bucket
    prefix = var.data_gke_man_bucket_prefix
  }
}
