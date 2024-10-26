/*

This Terraform configuration file is responsible for setting up the monitoring and alerting.
It conditionally includes resources to enable metrics and create necessary Kubernetes ConfigMaps
and Prometheus rules based on the 'enable_metrics' variable. The configuration retrieves remote
state outputs from the Prometheus stack to integrate dashboards and alert rules for cert-manager.

Usage:
- Set the variable 'enable_metrics' to 'true' to enable metrics and deploy the monitoring resources.
- When 'enable_metrics' is 'false', the monitoring resources will not be deployed.

Variables:
- enable_metrics: A boolean variable to control whether metrics and monitoring
  resources should be deployed.

Dependencies:
- Requires a Prometheus and Grafana stack deployed and configured to use the outputs for
  dashboard labels and alert rules.
*/

locals {
  grafana_dashboard_label_key = try(data.terraform_remote_state.prom_stack[0].outputs.grafana_dashboard_label_key, null)
  grafana_dashboard_label_value = try(data.terraform_remote_state.prom_stack[0].outputs.grafana_dashboard_label_value, null)
  prometheus_selector_key = try(data.terraform_remote_state.prom_stack[0].outputs.prometheus_selector_key, null)
  prometheus_selector_value = try(data.terraform_remote_state.prom_stack[0].outputs.prometheus_selector_value, null)
  alert_severity_critical = try(data.terraform_remote_state.prom_stack[0].outputs.alert_severity_critical, null)
  alert_severity_info = try(data.terraform_remote_state.prom_stack[0].outputs.alert_severity_info, null)
  alert_severity_warning = try(data.terraform_remote_state.prom_stack[0].outputs.alert_severity_warning, null)
}

# Retrieve Prom stack from TF state
data "terraform_remote_state" "prom_stack" {
  count   = var.enable_metrics ? 1 : 0
  backend = "gcs"
  config = {
    bucket = var.data_prom_stack_bucket
    prefix = var.data_prom_stack_bucket_prefix
  }
}

resource "kubernetes_config_map" "dashboards" {
  count   = var.enable_metrics ? 1 : 0
  metadata {
    namespace = local.namespace
    name = "external-secrets-dashboards"
    labels = {
      (local.grafana_dashboard_label_key != null ? local.grafana_dashboard_label_key : "") = (local.grafana_dashboard_label_value != null ? local.grafana_dashboard_label_value : "")
    }
  }
  data = {
    "external-secrets.json" = file("${path.module}/dashboard/main.json")
  }
}

# Create Prometheus rule alerts
resource "kubernetes_manifest" "prometheus_external_secrets_alert_rules" {
  count   = var.enable_metrics ? 1 : 0
  depends_on = [helm_release.external_secrets]
  manifest = {
    "apiVersion" = "monitoring.coreos.com/v1"
    "kind" = "PrometheusRule"
    "metadata" = {
      "labels" = {
        (local.prometheus_selector_key != null ? local.prometheus_selector_key : "") = (local.prometheus_selector_value != null ? local.prometheus_selector_value : "")
      }
      "name" = "external-secrets-rules"
      "namespace" = local.namespace
    }
    "spec" = {
      "groups" = [
          {
            "name" = "external-secrets"
            "rules" = [
              {
                "alert" = "ESOWebhookStatus"
                "expr" = <<-EOF
                  (sum(increase(controller_runtime_webhook_requests_total{service=~"external-secrets.*",code="500"}[1m]))
                  /
                  sum(increase(controller_runtime_webhook_requests_total{service=~"external-secrets.*"}[1m]))) > 10
                EOF
                "for" = "10m"
                "labels" = {
                  "severity" = (local.alert_severity_warning != null ? local.alert_severity_warning : "")
                },
                "annotations" = {
                  "summary" = "ESO webhook request error percentage {{ $value }}%"
                  "description" = "The webhook HTTP status code indicates that a HTTP Request was answered successfully or not. If the Webhook pod is not able to serve the requests properly then that failure may cascade down to the controller or any other user of kube-apiserver."
                },
              },{
                "alert" = "ESOWebhookWorkqueue"
                "annotations" = {
                  "description" = "If the workqueue depth is > 0 for a longer period of time then this is an indicator for the controller not being able to reconcile resources in time. I.e. delivery of secret updates is delayed."
                  "summary" = "The {{ $labels.name }} ESO controller workqueue depth. Depth {{ $value }}"
                }
                "expr" = <<-EOF
                  sum(
                    workqueue_depth{service=~"external-secrets.*"}
                  ) by (name) > 0
                EOF
                "for" = "0"
                "labels" = {
                  "severity" = (local.alert_severity_warning != null ? local.alert_severity_warning : "")
                }
              },{
                "alert" = "ESOControllerReconcileLatency"
                "annotations" = {
                  "description" = "The controller should be able to reconcile resources within a reasonable time frame. When latency is high secret delivery may impacted."
                  "summary" = "ESO controllers {{ $labels.controller }}, p99: {{ $value }}"
                }
                "expr" = <<-EOF
                  histogram_quantile(0.99,
                    sum(rate(controller_runtime_reconcile_time_seconds_bucket{service=~"external-secrets.*"}[5m])) by (le, controller)
                  ) > 2
                EOF
                "for" = "0"
                "labels" = {
                  "severity" = (local.alert_severity_warning != null ? local.alert_severity_warning : "")
                }
              }, {
                "alert" = "ESOControllerReconcileError"
                "expr" = <<-EOF
                  (sum(increase(
                    controller_runtime_reconcile_total{service=~"external-secrets.*",result="error"}[1m])
                  ) by (controller)) > 5
                EOF
                "for" = "10m"
                "labels" = {
                  "severity" = (local.alert_severity_critical != null ? local.alert_severity_critical : "")
                }
                "annotations" = {
                  "summary" = "ESO controller {{ $labels.controller }} reconcile errors: {{ $value}} ."
                  "description" = "The controller should be able to reconcile resources without errors. When errors occur secret delivery may be impacted which could cascade down to the secret consuming applications"
                }
              }
          ]
        }
      ]
    }
  }
}
