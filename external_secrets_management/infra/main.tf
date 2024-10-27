/**
 * Terraform configuration for managing external secrets in Kubernetes,
 * leveraging Vault for dynamic secret generation and static secret retrieval.
 * This setup facilitates secure access to database credentials and TLS certificates for SSO,
 * as well as Keycloak database credentials, within a Kubernetes environment named Kubert.
 *
 * External secrets are dynamically generated for database SSO and statically retrieved for Keycloak,
 * ensuring credentials are securely managed and rotated according to policies defined in Vault.
 */

locals {
  # Retrieve the database SSO service name from the Vault Terraform state
  database_sso_service_name = data.terraform_remote_state.vault_config.outputs.pki_database_sso_service_name

  # Namespaces from the GKE management Terraform state, used to deploy secrets
  namespace_security = data.terraform_remote_state.gke_man.outputs.kubert_security_namespace
  namespace_sso = data.terraform_remote_state.gke_man_after.outputs.kubert_sso_namespace
  namespace_observability = data.terraform_remote_state.gke_man_after.outputs.kubert_observability_namespace
  namespace_assistant = data.terraform_remote_state.gke_man_after.outputs.kubert_assistant_namespace

  # Names for the dynamic secret generators
  vault_sso_generator_name = "vault-database-sso-pki"
  vault_keycloak_database_name = "vault-keycloak-database-role"
  vault_keycloak_metrics_database_name = "vault-keycloak-metrics-database-role"

  # Database service details, fetched from the database SSO Terraform state
  database_sso_name = try(data.terraform_remote_state.database_sso[0].outputs.database_name, null)
  database_sso_port = try(data.terraform_remote_state.database_sso[0].outputs.database_port, null)

  # The name of the SecretStore custom resource representing Vault
  vault_secret_store_name = "vault-backend"

  # Key mappings for database connection details in the generated Kubernetes secret
  database_sso_data_keys = {
    host_key = "db-host"
    port_key = "db-port"
    database_key = "db-name"
    user_key = "db-username"
    password_key = "db-password"
  }

  database_sso_metrics_data_keys = {
    user_key = "db-username"
    password_key = "db-password"
  }

  # Keycloak admin credentials key, retrieved from the Vault Terraform state
  kv_keycloak_admin_cred = data.terraform_remote_state.vault_config.outputs.kv_keycloak_admin_cred
  # Grafana admin credentials key, retrieved from the Vault Terraform state
  kv_grafana_admin_cred = data.terraform_remote_state.vault_config.outputs.kv_grafana_admin_cred
  # KV vault path to lobechat openai api key
  kv_lobechat_openai_api_key = data.terraform_remote_state.vault_config.outputs.kv_path_lobechat_openai_key
  # KV vault path to lobechat anthropic api key
  kv_lobechat_anthropic_api_key = data.terraform_remote_state.vault_config.outputs.kv_lobechat_anthropic_api_key
  # KV vault path to lobechat access key
  kv_lobechat_access_key = data.terraform_remote_state.vault_config.outputs.kv_lobechat_admin_cred

  # KV vault path to alertmanager client credentials
  alertmanager_secret_path = try(data.terraform_remote_state.kc_man[0].outputs.client_alertmanager_vault_kv_path,null)
  # KV vault path to opencost client credentials
  opencost_secret_path = try(data.terraform_remote_state.kc_man[0].outputs.client_opencost_vault_kv_path,null)
  # KV vault path to lobechat client credentials
  lobechat_secret_path = try(data.terraform_remote_state.kc_man[0].outputs.client_lobechat_vault_kv_path,null)
  # KV vault path to ollama client credentials
  ollama_secret_path = try(data.terraform_remote_state.kc_man[0].outputs.client_ollama_vault_kv_path,null)
}

# External secret for SSO database credentials
# Utilizes the dynamic secret generator to create and manage TLS certificates for secure database access.
resource "kubernetes_manifest" "vault_pki_external_secret" {
  manifest = {
    "apiVersion" = "external-secrets.io/v1beta1"
    "kind" = "ExternalSecret"
    "metadata" = {
      "name" = local.vault_sso_generator_name
      "namespace" = local.namespace_sso
    }
    "spec" = {
      "refreshInterval" = "24h" # once a day
      "target" = {
        "name" = var.vault_database_sso_tls_secret_name
        "template" = {
          "type" = "kubernetes.io/tls"
          "metadata" = {
            "annotations" = {
              "replicator.v1.mittwald.de/replication-allowed" = "true"
              "replicator.v1.mittwald.de/replicate-to" = "${local.namespace_security}"
            }
          }
          "data" = {
            "tls.crt" = "{{ .certificate }}"
            "tls.key" = "{{ .private_key }}"
            "ca.crt"  = <<EOF
{{ $certArray := .ca_chain | fromJson}}
{{- range $certArray }}
{{ . }}
{{- end }}
            EOF
          }
        }
      }
      "dataFrom" = [{
        "sourceRef" = {
          "generatorRef" = {
            "apiVersion" = "generators.external-secrets.io/v1alpha1"
            "kind" = "VaultDynamicSecret"
            "name" = local.vault_sso_generator_name
          }
        }
      }]
    }
  }
}

# External secret for Keycloak database credentials
# Leverages a static role generator for retrieving consistent database credentials for Keycloak,
# managed and rotated by Vault.
resource "kubernetes_manifest" "keycloak_database_external_secret" {
  count   = var.configure_sso_database ? 1 : 0
  manifest = {
    "apiVersion" = "external-secrets.io/v1beta1"
    "kind" = "ExternalSecret"
    "metadata" = {
      "name" = local.vault_keycloak_database_name
      "namespace" = local.namespace_sso
    }
    "spec" = {
      "refreshInterval" = "20m" # every 20 minutes
      "target" = {
        "name" = var.vault_keycloak_database_secret_name
        "template" = {
          "type" = "Opaque"
          "metadata" = {}
          "data" = {
            "${local.database_sso_data_keys.database_key}" = "${local.database_sso_name}"
            "${local.database_sso_data_keys.user_key}" = "{{ .username }}"
            "${local.database_sso_data_keys.password_key}" = "{{ .password }}"
            "${local.database_sso_data_keys.host_key}" = format("%s.%s.svc.cluster.local", local.database_sso_service_name,local.namespace_sso)
            "${local.database_sso_data_keys.port_key}" = "${local.database_sso_port}"
          }
        }
      }
      "dataFrom" = [{
        "sourceRef" = {
          "generatorRef" = {
            "apiVersion" = "generators.external-secrets.io/v1alpha1"
            "kind" = "VaultDynamicSecret"
            "name" = local.vault_keycloak_database_name
          }
        }
      }]
    }
  }
}

# External secret for Keycloak admin credentials
# Manages the retrieval of Keycloak admin credentials, ensuring secure and controlled access to
# administrative functions.
resource "kubernetes_manifest" "keycloak_admin_secret" {
  manifest = {
    "apiVersion" = "external-secrets.io/v1beta1"
    "kind" = "ExternalSecret"
    "metadata" = {
      "name" = "keycloak-admin-user"
      "namespace" = local.namespace_sso
    }
    "spec" = {
      "refreshInterval" = "0"
      "secretStoreRef" = {
        "name" = local.vault_secret_store_name
        "kind" = "SecretStore"
      }
      "target" = {
        "name" = var.vault_keycloak_admin_secret_name
        "template" = {
          "type" = "Opaque"
          "metadata" = {}
          "data" = {
            "admin-password" = "{{ .password }}"
          }
        }
      }
      "data" = [{
        "secretKey" = "password"
        "remoteRef" = {
          "key" = local.kv_keycloak_admin_cred
          "property" = "password"
        }
      }]
    }
  }
}

# External secret for Grafana admin credentials
resource "kubernetes_manifest" "grafana_admin_secret" {
  manifest = {
    "apiVersion" = "external-secrets.io/v1beta1"
    "kind" = "ExternalSecret"
    "metadata" = {
      "name" = "grafana-admin-user"
      "namespace" = local.namespace_observability
    }
    "spec" = {
      "refreshInterval" = "48h" # every 2 days
      "secretStoreRef" = {
        "name" = local.vault_secret_store_name
        "kind" = "SecretStore"
      }
      "target" = {
        "name" = var.vault_grafana_admin_secret_name
        "template" = {
          "type" = "Opaque"
          "metadata" = {}
          "data" = {
            "${var.grafana_admin_secret_password_key}" = "{{ .password }}",
            "${var.grafana_admin_secret_user_key}" = "${var.grafana_admin_secret_user_value}"
          }
        }
      }
      "data" = [{
        "secretKey" = "password"
        "remoteRef" = {
          "key" = local.kv_grafana_admin_cred
          "property" = "password"
        }
      }]
    }
  }
}

# Valid 32 Byte Base64 URL encoding set that will decode to 24 []byte AES-192 secret
resource "random_password" "cookie_secret_alert_manager" {
  length           = 32
  override_special = "-_"
}

# External secret for Alertmanager Keycloak Client credentials
resource "kubernetes_manifest" "alertmanager_oauth_secret" {
  count   = var.configure_keycloak ? 1 : 0
  manifest = {
    "apiVersion" = "external-secrets.io/v1beta1"
    "kind" = "ExternalSecret"
    "metadata" = {
      "name" = "alertmanager-client"
      "namespace" = local.namespace_observability
    }
    "spec" = {
      "refreshInterval" = "0"
      "secretStoreRef" = {
        "name" = local.vault_secret_store_name
        "kind" = "SecretStore"
      }
      "target" = {
        "name" = var.alertmanager_secret_name
        "template" = {
          "type" = "Opaque"
          "metadata" = {}
          "data" = {
            "cookie-secret" = "${random_password.cookie_secret_alert_manager.result}",
            "client-id"     = "{{ .client_id }}",
            "client-secret" = "{{ .client_secret }}",
          }
        }
      }
      "data" = [{
        "secretKey" = "client_id"
        "remoteRef" = {
          "key" = local.alertmanager_secret_path
          "property" = "${data.terraform_remote_state.kc_man[0].outputs.kc_client_client_id_key}"
        }
      },{
        "secretKey" = "client_secret"
        "remoteRef" = {
          "key" = local.alertmanager_secret_path
          "property" = "${data.terraform_remote_state.kc_man[0].outputs.kc_client_client_secret_key}"
        }
      }]
    }
  }
}

# External secret for Keycloak database credentials
# Leverages a static role generator for retrieving consistent database credentials for metrics user,
# managed and rotated by Vault.
resource "kubernetes_manifest" "keycloak_metrics_database_external_secret" {
  count   = var.configure_sso_database ? 1 : 0
  manifest = {
    "apiVersion" = "external-secrets.io/v1beta1"
    "kind" = "ExternalSecret"
    "metadata" = {
      "name" = local.vault_keycloak_metrics_database_name
      "namespace" = local.namespace_sso
    }
    "spec" = {
      "refreshInterval" = "20m" # every 20 minutes
      "target" = {
        "name" = var.vault_keycloak_metrics_secret_name
        "template" = {
          "type" = "Opaque"
          "metadata" = {}
          "data" = {
            "${local.database_sso_metrics_data_keys.user_key}" = "{{ .username }}"
            "${local.database_sso_metrics_data_keys.password_key}" = "{{ .password }}"
          }
        }
      }
      "dataFrom" = [{
        "sourceRef" = {
          "generatorRef" = {
            "apiVersion" = "generators.external-secrets.io/v1alpha1"
            "kind" = "VaultDynamicSecret"
            "name" = local.vault_keycloak_metrics_database_name
          }
        }
      }]
    }
  }
}

resource "random_id" "lobechat_random_base64" {
  byte_length = 24
}

# External secret for Lobe chat
resource "kubernetes_manifest" "lobechat_secret" {
  count   = var.configure_keycloak ? 1 : 0
  manifest = {
    "apiVersion" = "external-secrets.io/v1beta1"
    "kind" = "ExternalSecret"
    "metadata" = {
      "name" = "lobechat"
      "namespace" = local.namespace_assistant
    }
    "spec" = {
      "refreshInterval" = "0"
      "secretStoreRef" = {
        "name" = local.vault_secret_store_name
        "kind" = "SecretStore"
      }
      "target" = {
        "name" = var.vault_lobechat_secret_name
        "template" = {
          "type" = "Opaque"
          "metadata" = {}
          "data" = {
            "ACCESS_CODE" = "{{ .password }}"
            "OPENAI_API_KEY" = "{{ .openai_api_key }}"
            "ANTHROPIC_API_KEY" = "{{ .anthropic_api_key }}"
            "KEYCLOAK_CLIENT_ID" = "{{ .client_id }}"
            "KEYCLOAK_CLIENT_SECRET" = "{{ .client_secret }}"
            "NEXT_AUTH_SECRET" = base64encode(random_id.lobechat_random_base64.b64_std)
          }
        }
      }
      "data" = [{
        "secretKey" = "password"
        "remoteRef" = {
          "key" = local.kv_lobechat_access_key
          "property" = "password"
        }
      },{
        "secretKey" = "openai_api_key"
        "remoteRef" = {
          "key" = local.kv_lobechat_openai_api_key
          "property" = "api_key"
        }
      },
      {
        "secretKey" = "anthropic_api_key"
        "remoteRef" = {
          "key" = local.kv_lobechat_anthropic_api_key
          "property" = "api_key"
        }
      },
      {
        "secretKey" = "client_id"
        "remoteRef" = {
          "key" = local.lobechat_secret_path
          "property" = "${data.terraform_remote_state.kc_man[0].outputs.kc_client_client_id_key}"
        }
      },{
        "secretKey" = "client_secret"
        "remoteRef" = {
          "key" = local.lobechat_secret_path
          "property" = "${data.terraform_remote_state.kc_man[0].outputs.kc_client_client_secret_key}"
        }
      }]
    }
  }
}

# Valid 32 Byte Base64 URL encoding set that will decode to 24 []byte AES-192 secret
resource "random_password" "cookie_secret_opencost" {
  length           = 32
  override_special = "-_"
}

# External secret for OpenCost Keycloak Client credentials
resource "kubernetes_manifest" "opencost_oauth_secret" {
  count   = var.configure_keycloak ? 1 : 0
  manifest = {
    "apiVersion" = "external-secrets.io/v1beta1"
    "kind" = "ExternalSecret"
    "metadata" = {
      "name" = "opencost-client"
      "namespace" = local.namespace_observability
    }
    "spec" = {
      "refreshInterval" = "0"
      "secretStoreRef" = {
        "name" = local.vault_secret_store_name
        "kind" = "SecretStore"
      }
      "target" = {
        "name" = var.opencost_secret_name
        "template" = {
          "type" = "Opaque"
          "metadata" = {}
          "data" = {
            "cookie-secret" = "${random_password.cookie_secret_opencost.result}",
            "client-id"     = "{{ .client_id }}",
            "client-secret" = "{{ .client_secret }}",
          }
        }
      }
      "data" = [{
        "secretKey" = "client_id"
        "remoteRef" = {
          "key" = local.opencost_secret_path
          "property" = "${data.terraform_remote_state.kc_man[0].outputs.kc_client_client_id_key}"
        }
      },{
        "secretKey" = "client_secret"
        "remoteRef" = {
          "key" = local.opencost_secret_path
          "property" = "${data.terraform_remote_state.kc_man[0].outputs.kc_client_client_secret_key}"
        }
      }]
    }
  }
}

# Valid 32 Byte Base64 URL encoding set that will decode to 24 []byte AES-192 secret
resource "random_password" "cookie_secret_ollama" {
  length           = 32
  override_special = "-_"
}

# External secret for Ollama Keycloak Client credentials
resource "kubernetes_manifest" "ollama_oauth_secret" {
  count   = var.configure_keycloak ? 1 : 0
  manifest = {
    "apiVersion" = "external-secrets.io/v1beta1"
    "kind" = "ExternalSecret"
    "metadata" = {
      "name" = "ollama-client"
      "namespace" = local.namespace_assistant
    }
    "spec" = {
      "refreshInterval" = "0"
      "secretStoreRef" = {
        "name" = local.vault_secret_store_name
        "kind" = "SecretStore"
      }
      "target" = {
        "name" = var.ollama_secret_name
        "template" = {
          "type" = "Opaque"
          "metadata" = {}
          "data" = {
            "cookie-secret" = "${random_password.cookie_secret_ollama.result}",
            "client-id"     = "{{ .client_id }}",
            "client-secret" = "{{ .client_secret }}",
          }
        }
      }
      "data" = [{
        "secretKey" = "client_id"
        "remoteRef" = {
          "key" = local.ollama_secret_path
          "property" = "${data.terraform_remote_state.kc_man[0].outputs.kc_client_client_id_key}"
        }
      },{
        "secretKey" = "client_secret"
        "remoteRef" = {
          "key" = local.ollama_secret_path
          "property" = "${data.terraform_remote_state.kc_man[0].outputs.kc_client_client_secret_key}"
        }
      }]
    }
  }
}
