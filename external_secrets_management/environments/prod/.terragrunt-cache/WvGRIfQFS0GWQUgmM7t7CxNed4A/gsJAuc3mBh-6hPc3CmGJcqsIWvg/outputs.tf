/**
 * Outputs for external secrets configuration.
 *
 * Copyright 2024 Translucent Computing Inc.
 */

output "database_sso_tls_secret_name" {
  value = var.vault_database_sso_tls_secret_name
  description = "Name of the secret that contains the TLS for PostgreSQL in SSO namespace."
}

output "keycloak_database_secret_name" {
  value = var.vault_keycloak_database_secret_name
  description = "Name of the secret that contains database data for Keycloak."
}

output "keycloak_admin_secret_name" {
  value = var.vault_keycloak_admin_secret_name
  description = "Name of the secret that contains Keycloak user admin credentials."
}

output "keycloak_metrics_secret_name" {
  value = var.vault_keycloak_metrics_secret_name
  description = "Name of the secret that contains Keycloak Metrics user credentials."
}

output "keycloak_database_secret_keys" {
  value = local.database_sso_data_keys
  description = "Secret key names for the database keycloak secret."
}

output "grafana_admin_secret_name" {
  value = var.vault_grafana_admin_secret_name
  description = "Name of the secret that contains Grafana user admin credentials."
}

output "grafana_admin_secret_user_key" {
  value = var.grafana_admin_secret_user_key
  description = "Secret key for Grafana admin username."
}

output "grafana_admin_secret_password_key" {
  value = var.grafana_admin_secret_password_key
  description = "Secret key for Grafana admin password."
}

output "alertmanager_secret_name" {
  value       = var.alertmanager_secret_name
  description = "Alertmanager Oauth2 proxy secret name."
}

output "opencost_secret_name" {
  value       = var.opencost_secret_name
  description = "OpenCost Oauth2 proxy secret name."
}

output "keycloak_metrics_database_secret_keys" {
  value       = local.database_sso_metrics_data_keys
  description = "Secret key names for the database keycloak metrics secret."
}

output "headlamp_secret_name" {
  value       = var.headlamp_secret_name
  description = "Headlamp KC client secret name."
}

output "lobechat_secret_name" {
  value = var.vault_lobechat_secret_name
  description = "Lobe chat credentials secret name."
}
