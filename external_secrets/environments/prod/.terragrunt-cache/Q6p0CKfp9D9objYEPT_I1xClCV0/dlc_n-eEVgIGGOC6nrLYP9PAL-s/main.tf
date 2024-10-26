/**
 * Main resources for external secrets deployment.
 *
 * Copyright 2024 Translucent Computing Inc.
 */

locals {
  namespace = data.terraform_remote_state.gke_man.outputs.kubert_security_namespace

  metrics = <<EOF
serviceMonitor:
  enabled: ${var.enable_metrics}
EOF

  issuer_name = "external-secrets-issuer"

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

  topologySpreadConstraints_webook = {
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

# Create selfsigned issuer
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

# Create certificate authoritiy
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

# Create Cert Issuer
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

# Deploy external secrets chart
resource "helm_release" "external_secrets" {
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"

  name             = var.chart_release_name
  version          = var.chart_version
  namespace        = local.namespace

  values = [
    "${file("values.yaml")}",
    yamlencode(local.affinity),
    yamlencode(local.topologySpreadConstraints),
    yamlencode({resources=var.resources}),
    yamlencode(local.webhook_cert_config),
    yamlencode({webhook={resources=var.webhook_resources}}),
    yamlencode(local.affinity_webhook),
    yamlencode(local.topologySpreadConstraints_webook),
    local.metrics
  ]

  set {
    name = "replicaCount"
    value =  var.replica_count
  }

  set {
    name = "webhook.replicaCount"
    value =  var.replica_count_webhook
  }


  # Conditional set for metrics
  dynamic "set" {
    for_each = var.enable_metrics ? [1] : []
    content {
      name  = "serviceMonitor.additionalLabels.${data.terraform_remote_state.prom_stack[0].outputs.prometheus_selector_key}"
      value = data.terraform_remote_state.prom_stack[0].outputs.prometheus_selector_value
    }
  }
}

# Deploy CRDs for ES
module "kubectl_apply_crds" {
  source                 = "../../../../../../modules/kubectl_wrapper"
  cluster_name           = data.google_container_cluster.cluster.name
  cluster_ca_certificate = data.google_container_cluster.cluster.master_auth[0].cluster_ca_certificate
  kube_host              = "https://${data.google_container_cluster.cluster.private_cluster_config[0].private_endpoint}"
  always-apply            = true
  command                = "kubectl apply -n ${local.namespace} -f crds.yaml"
}
