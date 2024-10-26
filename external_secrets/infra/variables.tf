/**
 * Variables for external secrets deployment.
 *
 * Copyright 2024 Translucent Computing Inc.
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

variable "data_gke_man_bucket" {
  description = "TF state GCS bucket for GKE management"
  type        = string
}

variable "data_gke_man_bucket_prefix" {
  description = "Folder for the GCS bucket for GKE management"
  type        = string
}

variable "data_prom_stack_bucket" {
  description = "TF state GCS bucket for Prom Stack deployment."
  type        = string
}

variable "data_prom_stack_bucket_prefix" {
  description = "Folder for the GCS bucket for Prom Stack deployment."
  type        = string
}

variable "chart_version" {
  description = "Helm chart version to deploy."
  type        = string
}

variable "chart_release_name" {
  type        = string
  description = "Helm chart release name"
}

variable "resources" {
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  description = "Compute Resources required by the container. CPU/RAM requests/limits"
}

variable "webhook_resources" {
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  description = "Compute Resources required by the container. CPU/RAM requests/limits"
}

# Create Cert - Variables
variable "cert_subject" {
  description = "Certificate subject"
  type = object({
    organizations = list(string)
    organizationalUnits = list(string)
  })
}

variable "cert_duration" {
  description = "External DNS issuer cert duration."
  type        = string
}

variable "cert_renew" {
  description = "External DNS issuer cert renewal."
  type        = string
}

variable "replica_count" {
  description = "Replica count for the main controller."
  type        = number
}

variable "replica_count_webhook" {
  description = "Replica count for the webhook."
  type        = number
}

variable "enable_metrics" {
  description = "Flag to metrics resource creation"
  type        = bool
  default     = false
}
