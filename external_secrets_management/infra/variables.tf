/**
 * Variables for external secrets configuration.
 */

variable "impersonate_account" {
  type        = string
  description = "The service account that TF used for Google provider."
}

variable "environment" {
  description = "The deployment environment."
  type        = string
}

variable "project_id" {
  description = "Project ID."
  type        = string
}

variable "cluster_name" {
  description = "Cluster name."
  type        = string
}

variable "cluster_location" {
  description = "Cluster zone or region."
  type        = string
}

# Data Sources

variable "data_gke_man_bucket" {
  description = "TF state GCS bucket for GKE management"
  type        = string
}

variable "data_gke_man_bucket_prefix" {
  description = "Folder for the GCS bucket for GKE management"
  type        = string
}

variable "data_gke_man_after_bucket" {
  description = "TF state GCS bucket for GKE management after Vault deployment."
  type        = string
}

variable "data_gke_man_after_bucket_prefix" {
  description = "Folder for the GCS bucket for GKE management after Vault deployment."
  type        = string
}

variable "data_vault_bucket" {
  description = "TF state GCS bucket for Vault deployment."
  type        = string
}

variable "data_vault_bucket_prefix" {
  description = "Folder for the GCS bucket for Vault deployment."
  type        = string
}

variable "data_vault_config_bucket" {
  description = "TF state GCS bucket for Vault configuration."
  type        = string
}

variable "data_vault_config_bucket_prefix" {
  description = "Folder for the GCS bucket for Vault configuration."
  type        = string
}

variable "data_database_sso_bucket" {
  description = "TF state GCS bucket for Database SSO deployment."
  type        = string
}

variable "data_database_sso_bucket_prefix" {
  description = "Folder for the GCS bucket for Database SSO deployment."
  type        = string
}

variable "data_kc_man_bucket" {
  description = "TF state GCS bucket for Keycloak management"
  type        = string
}

variable "data_kc_man_bucket_prefix" {
  description = "Folder for the GCS bucket for Keycloak management"
  type        = string
}

variable "data_kc_bucket" {
  description = "TF state GCS bucket for Keycloak"
  type        = string
}

variable "data_kc_bucket_prefix" {
  description = "Folder for the GCS bucket for Keycloak"
  type        = string
}

# Secret properties

variable "vault_database_sso_tls_secret_name" {
  description = "Name of the secret where the Vault certificated is stored."
  type        = string
}

variable "vault_database_sso_tls_ttl" {
  description = "The time after which this certificate will no longer be valid."
  type        = string
}

variable "vault_keycloak_database_secret_name" {
  description = "The name of the Kubernetes secret where Keycloak database data is stored."
  type        = string
}

variable "vault_keycloak_metrics_secret_name" {
  description = "The name of the Kubernetes secret where Keycloak Metrics user data is stored."
  type        = string
}

variable "vault_keycloak_admin_secret_name" {
  description = "The secret name of Kubernetes secret that contains Keycloak admin user credentials."
  type        = string
}

variable "vault_grafana_admin_secret_name" {
  description = "The secret name of Kubernetes secret that contains Grafana admin user credentials."
  type        = string
}

variable "grafana_admin_secret_user_value" {
  description = "Grafana admin username."
  type        = string
}

variable "grafana_admin_secret_user_key" {
  description = "Grafana admin username secret key."
  type        = string
}

variable "grafana_admin_secret_password_key" {
  description = "Grafana admin password secret key."
  type        = string
}

variable "alertmanager_secret_name" {
  type        = string
  description = "Name of Alertmanager secret"
}
variable "vault_lobechat_secret_name" {
  description = "The secret name of Kubernetes secret that contains Lobe chat credentials."
  type        = string
}
variable "opencost_secret_name" {
  type        = string
  description = "Name of OpenCost secret"
}

variable "configure_keycloak" {
  description = "Flag to control Keycloak resource creation"
  type        = bool
  default     = false
}

variable "configure_sso_database" {
  description = "Flag to control the SSO database configuration."
  type        = bool
  default     = false
}

variable "ollama_secret_name" {
  type        = string
  description = "Name of Ollama Keycloak Client secret"
}
