/**
 * Vault Dynamic Secret Generators for Kubernetes External Secrets
 * This file defines custom resources for generating dynamic secrets in Kubernetes,
 * using Vault as the backend. These resources allow for secure, automated retrieval
 * and rotation of secrets such as TLS certificates and database credentials.
 */

# Dynamic secret generator for database SSO certificates
# This resource configures a VaultDynamicSecret custom resource to dynamically generate
# TLS certificates for SSO (Single Sign-On) for databases. It specifies the Vault path,
# method, and parameters for the certificate request, ensuring that fresh certificates
# are generated as needed, following the specifications and TTL defined.
resource "kubernetes_manifest" "vault_pki_generator" {
  manifest = {
    "apiVersion" = "generators.external-secrets.io/v1alpha1"
    "kind" = "VaultDynamicSecret"
    "metadata" = {
      "name" = local.vault_sso_generator_name
      "namespace" = local.namespace_sso
    }
    "spec" = {
      "method" = "POST"
      "path" = data.terraform_remote_state.vault_config.outputs.vault_pki_database_sso_issuer_role_path
      "parameters" = {
        "common_name" = local.database_sso_service_name
        "alt_names" = join(", ",[
          format("%s",local.database_sso_service_name),
          format("*.%s.%s.svc.cluster.local", local.database_sso_service_name,local.namespace_sso),
          format("%s.%s.svc.cluster.local", local.database_sso_service_name,local.namespace_sso),
          format("*.%s-hl.%s.svc.cluster.local", local.database_sso_service_name,local.namespace_sso),
          format("%s-hl.%s.svc.cluster.local", local.database_sso_service_name,local.namespace_sso)
        ])
        "ip_sans" = "127.0.0.1"
        "format" = "pem"
        "private_key_format" = "pem"
        "ttl" = var.vault_database_sso_tls_ttl
      }
      "provider" = {
        "server" = data.terraform_remote_state.vault.outputs.vault_url
        "caProvider" = {
          "name" = data.terraform_remote_state.vault.outputs.vault_client_tls_secret_name
          "key"  = "ca.crt"
          "type" = "Secret"
        }
        "tls" = {
          "certSecretRef" = {
            "name" = data.terraform_remote_state.vault.outputs.vault_client_tls_secret_name
            "key"  = "tls.crt"
          }
          "keySecretRef" = {
            "name" = data.terraform_remote_state.vault.outputs.vault_client_tls_secret_name
            "key"  = "tls.key"
          }
        }
        "auth" = {
          "kubernetes" = {
            "role" = data.terraform_remote_state.vault_config.outputs.generic_kubernetes_vault_auth_role_name
            "mountPath" = data.terraform_remote_state.vault_config.outputs.vault_kubernetes_path
          }
        }
      }
    }
  }
}

# Dynamic secret generator for static Keycloak database credentials
# This configuration retrieves static credentials for Keycloak's database from Vault, ensuring
# that the service has access to the database with a predefined set of credentials that are managed
# and rotated by Vault according to its configuration. This setup leverages the static secret
# mechanism in Vault, providing stable credentials with automatic rotation.
resource "kubernetes_manifest" "vault_database_sso_static_role_generator" {
  count   = var.configure_sso_database ? 1 : 0
  manifest = {
    "apiVersion" = "generators.external-secrets.io/v1alpha1"
    "kind" = "VaultDynamicSecret"
    "metadata" = {
      "name" = local.vault_keycloak_database_name
      "namespace" = local.namespace_sso
    }
    "spec" = {
      "method" = "GET"
      "path" = data.terraform_remote_state.vault_config.outputs.vault_database_sso_keycloak_static_role_path
      "provider" = {
        "server" = data.terraform_remote_state.vault.outputs.vault_url
        "caProvider" = {
          "name" = data.terraform_remote_state.vault.outputs.vault_client_tls_secret_name
          "key"  = "ca.crt"
          "type" = "Secret"
        }
        "tls" = {
          "certSecretRef" = {
            "name" = data.terraform_remote_state.vault.outputs.vault_client_tls_secret_name
            "key"  = "tls.crt"
          }
          "keySecretRef" = {
            "name" = data.terraform_remote_state.vault.outputs.vault_client_tls_secret_name
            "key"  = "tls.key"
          }
        }
        "auth" = {
          "kubernetes" = {
            "role" = data.terraform_remote_state.vault_config.outputs.generic_kubernetes_vault_auth_role_name
            "mountPath" = data.terraform_remote_state.vault_config.outputs.vault_kubernetes_path
          }
        }
      }
    }
  }
}

resource "kubernetes_manifest" "vault_database_sso_static_role_generator_metrics" {
  count   = var.configure_sso_database ? 1 : 0
  manifest = {
    "apiVersion" = "generators.external-secrets.io/v1alpha1"
    "kind" = "VaultDynamicSecret"
    "metadata" = {
      "name" = local.vault_keycloak_metrics_database_name
      "namespace" = local.namespace_sso
    }
    "spec" = {
      "method" = "GET"
      "path" = data.terraform_remote_state.vault_config.outputs.vault_database_sso_metrics_static_role_path
      "provider" = {
        "server" = data.terraform_remote_state.vault.outputs.vault_url
        "caProvider" = {
          "name" = data.terraform_remote_state.vault.outputs.vault_client_tls_secret_name
          "key"  = "ca.crt"
          "type" = "Secret"
        }
        "tls" = {
          "certSecretRef" = {
            "name" = data.terraform_remote_state.vault.outputs.vault_client_tls_secret_name
            "key"  = "tls.crt"
          }
          "keySecretRef" = {
            "name" = data.terraform_remote_state.vault.outputs.vault_client_tls_secret_name
            "key"  = "tls.key"
          }
        }
        "auth" = {
          "kubernetes" = {
            "role" = data.terraform_remote_state.vault_config.outputs.generic_kubernetes_vault_auth_role_name
            "mountPath" = data.terraform_remote_state.vault_config.outputs.vault_kubernetes_path
          }
        }
      }
    }
  }
}
