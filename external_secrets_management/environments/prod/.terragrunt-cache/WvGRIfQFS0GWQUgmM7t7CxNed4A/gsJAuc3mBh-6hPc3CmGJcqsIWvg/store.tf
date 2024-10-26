/**
 * SecretStore Configuration for External Secrets in Kubernetes with Vault Backend
 *
 * Copyright 2024 Translucent Computing Inc.
 */

locals {
  // Create a list of namespaces dynamically
  namespaces = [
    local.namespace_security,
    local.namespace_observability,
    local.namespace_sso,
    local.namespace_assistant
  ]

  // Define a common spec for the SecretStore
  vault_spec = {
    "provider" = {
      "vault" = {
        "server" = data.terraform_remote_state.vault.outputs.vault_url
        "path"   = data.terraform_remote_state.vault_config.outputs.vault_kv_2_path
        "version" = "v2"
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
            "role"      = data.terraform_remote_state.vault_config.outputs.generic_kubernetes_vault_auth_role_name
            "mountPath" = data.terraform_remote_state.vault_config.outputs.vault_kubernetes_path
          }
        }
      }
    }
  }
}

resource "kubernetes_manifest" "vault_secret_store" {
  for_each = toset(local.namespaces)

  manifest = {
    "apiVersion" = "external-secrets.io/v1beta1"
    "kind"       = "SecretStore"
    "metadata" = {
      "name"      = local.vault_secret_store_name
      "namespace" = each.key
    }
    "spec" = local.vault_spec
  }
}
