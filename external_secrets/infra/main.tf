/**
 * Main resources for external secrets deployment.
 * This configuration defines local settings, certificates, and the Helm release
 * to deploy External Secrets in a Kubernetes cluster.
 */

locals {
  # Define the Kubernetes namespace where external secrets will be deployed, pulled from remote state.
  namespace = data.terraform_remote_state.gke_man.outputs.kubert_security_namespace

  # YAML configuration for enabling or disabling metrics in the ServiceMonitor
  metrics = <<EOF
serviceMonitor:
  enabled: ${var.enable_metrics}
EOF

  # Define the name for the certificate issuer, used by cert-manager to issue certificates for the Webhook.
  issuer_name = "external-secrets-issuer"

  # Webhook certificate configuration for cert-manager, enabling TLS for the validating webhook.
  webhook_cert_config = {
    "webhook": {
      "certManager": {
        "cert": {
          "create": true
          "issuerRef": {
            "group": "cert-manager.io"
            "kind": "Issuer"
            "name": local.issuer_name
          }
          "duration": var.cert_duration
          "renewBefore": var.cert_renew
        }
      }
    }
  }

  # Pod affinity rules to ensure External Secrets Core Controller pods are not scheduled on the same node.
  affinity = {
    "affinity": {
      "podAntiAffinity": {
        "requiredDuringSchedulingIgnoredDuringExecution": [
          {
            "labelSelector": {
              "matchLabels": {
                "app.kubernetes.io/name": var.chart_release_name
                "app.kubernetes.io/instance": var.chart_release_name
              }
            }
            "topologyKey": "kubernetes.io/hostname"
          }
        ]
      }
    }
  }

  # Pod affinity rules for the Webhook pod to avoid scheduling on the same node as other webhook instances.
  affinity_webhook = {
    "webhook": {
      "affinity": {
        "podAntiAffinity": {
          "requiredDuringSchedulingIgnoredDuringExecution": [
            {
              "labelSelector": {
                "matchLabels": {
                  "app.kubernetes.io/name": "${var.chart_release_name}-webhook"
                  "app.kubernetes.io/instance": var.chart_release_name
                }
              }
              "topologyKey": "kubernetes.io/hostname"
            }
          ]
        }
      }
    }
  }

  # Constraints to spread Core Controller pods across zones for improved resilience and availability.
  topologySpreadConstraints = {
    "topologySpreadConstraints": [
      {
        "maxSkew": 1
        "topologyKey": "topology.kubernetes.io/zone"
        "whenUnsatisfiable": "DoNotSchedule"
        "labelSelector": {
          "matchLabels": {
            "app.kubernetes.io/name": var.chart_release_name
            "app.kubernetes.io/instance": var.chart_release_name
          }
        }
      }
    ]
  }

  # Similar topology spread constraints for Webhook pods to balance their placement across zones.
  topologySpreadConstraints_webhook = {
    "webhook": {
      "topologySpreadConstraints": [
        {
          "maxSkew": 1
          "topologyKey": "topology.kubernetes.io/zone"
          "whenUnsatisfiable": "DoNotSchedule"
          "labelSelector": {
            "matchLabels": {
              "app.kubernetes.io/name": "${var.chart_release_name}-webhook"
              "app.kubernetes.io/instance": var.chart_release_name
            }
          }
        }
      ]
    }
  }
}

# Create a self-signed issuer for cert-manager to generate certificates used by the Webhook Pod for TLS.
resource "kubernetes_manifest" "selfsigned_issuer" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind" = "Issuer"
    "metadata" = {
      "name" = "external-secret-self-signed"
      "namespace" = local.namespace
    }
    "spec" = {
      "selfSigned" = {}
    }
  }
}

# Define a certificate authority (CA) for the External Secrets Webhook using cert-manager.
# This CA will issue certificates for secure TLS communication.
resource "kubernetes_manifest" "external_secret_ca_certs" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind" = "Certificate"
    "metadata" = {
      "name" = "selfsigned-external-secret-ca"
      "namespace" = local.namespace
    }
    "spec" = {
      "isCA" = true
      "commonName" = "External Secret CA"
      "secretName" = "external-secret-ca-tls"
      "subject" = var.cert_subject
      "duration" = "87660h0m0s" # 10 years
      "privateKey" = {
        "algorithm" = "ECDSA"
        "size" = 256
      }
      "issuerRef" = {
        "group" = "cert-manager.io"
        "kind" = "Issuer"
        "name" = "external-secret-self-signed"
      }
    }
  }
}

# Create a certificate issuer that uses the above CA certificate, providing a trusted source for the Webhook.
resource "kubernetes_manifest" "cert_issuer" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind" = "Issuer"
    "metadata" = {
      "name" = local.issuer_name
      "namespace" = local.namespace
    }
    "spec" = {
      "ca" = {
        "secretName" = "external-secret-ca-tls"
      }
    }
  }
}

# Deploy the External Secrets Helm chart with customized values and settings for
# the Core Controller, Webhook, and Cert/CRD Controller.
resource "helm_release" "external_secrets" {
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"

  name             = var.chart_release_name
  version          = var.chart_version
  namespace        = local.namespace

  values = [
    "${file("values.yaml")}",                               # Main Helm values file
    yamlencode(local.affinity),                             # Pod affinity configuration for Core Controller
    yamlencode(local.topologySpreadConstraints),            # Pod spread constraints for Core Controller
    yamlencode({resources=var.resources}),                  # Resource requests and limits for Core Controller
    yamlencode(local.webhook_cert_config),                  # Webhook certificate configuration
    yamlencode({webhook={resources=var.webhook_resources}}),# Webhook resource configuration
    yamlencode(local.affinity_webhook),                     # Affinity rules for Webhook pods
    yamlencode(local.topologySpreadConstraints_webhook),    # Spread constraints for Webhook pods
    local.metrics                                           # Enable or disable metrics in ServiceMonitor
  ]

  # Configure replica counts for main and webhook components
  set {
    name = "replicaCount"
    value =  var.replica_count
  }

  set {
    name = "webhook.replicaCount"
    value =  var.replica_count_webhook
  }


  # Conditionally add Prometheus metrics configuration if metrics are enabled
  dynamic "set" {
    for_each = var.enable_metrics ? [1] : []
    content {
      name  = "serviceMonitor.additionalLabels.${data.terraform_remote_state.prom_stack[0].outputs.prometheus_selector_key}"
      value = data.terraform_remote_state.prom_stack[0].outputs.prometheus_selector_value
    }
  }
}
