# External Secrets Management Infra

This directory provides the Terraform configurations for managing the secret storage backend configuration, using Vault as the provider. It sets up `SecretStore` resources in multiple namespaces to facilitate secure access to external secrets across different services within Kubernetes.

## Structure and Purpose

- **data.tf**: 
  - Defines data sources that retrieve information and state for Vault, GKE, SSO database, and Keycloak.
  - Configures access to multiple Terraform states for GKE and Vault to ensure that secrets are securely managed and accessible in the Kubernetes environment.

- **generator.tf**:
  - Configures custom resources to generate dynamic secrets in Kubernetes, using Vault as the backend.

- **main.tf**:
  - This file defines resources for managing external secrets in Kubernetes with Vault as the backend. It leverages both dynamic and static secret retrieval for different services.

- **outputs.tf**:
  - Defines output values to expose essential information about the deployment. This allows other modules or services to reference key configurations, such as URLs, secrets paths, and role names.

- **store.tf**:
  - Configures `SecretStore` resources across various namespaces to connect Kubernetes with Vault securely. 
  - The configuration ensures that each namespace can access Vault secrets specific to its services, using Kubernetes-native authentication and TLS.

- **variables.tf**:
  - Defines input variables for configuring various parameters in the deployment, including Vault paths, service accounts, and resource limits.


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| alertmanager\_secret\_name | Name of Alertmanager secret | `string` | n/a | yes |
| cluster\_location | Cluster zone or region. | `string` | n/a | yes |
| cluster\_name | Cluster name. | `string` | n/a | yes |
| configure\_keycloak | Flag to control Keycloak resource creation | `bool` | `false` | no |
| configure\_sso\_database | Flag to control the SSO database configuration. | `bool` | `false` | no |
| data\_database\_sso\_bucket | TF state GCS bucket for Database SSO deployment. | `string` | n/a | yes |
| data\_database\_sso\_bucket\_prefix | Folder for the GCS bucket for Database SSO deployment. | `string` | n/a | yes |
| data\_gke\_man\_after\_bucket | TF state GCS bucket for GKE management after Vault deployment. | `string` | n/a | yes |
| data\_gke\_man\_after\_bucket\_prefix | Folder for the GCS bucket for GKE management after Vault deployment. | `string` | n/a | yes |
| data\_gke\_man\_bucket | TF state GCS bucket for GKE management | `string` | n/a | yes |
| data\_gke\_man\_bucket\_prefix | Folder for the GCS bucket for GKE management | `string` | n/a | yes |
| data\_kc\_bucket | TF state GCS bucket for Keycloak | `string` | n/a | yes |
| data\_kc\_bucket\_prefix | Folder for the GCS bucket for Keycloak | `string` | n/a | yes |
| data\_kc\_man\_bucket | TF state GCS bucket for Keycloak management | `string` | n/a | yes |
| data\_kc\_man\_bucket\_prefix | Folder for the GCS bucket for Keycloak management | `string` | n/a | yes |
| data\_vault\_bucket | TF state GCS bucket for Vault deployment. | `string` | n/a | yes |
| data\_vault\_bucket\_prefix | Folder for the GCS bucket for Vault deployment. | `string` | n/a | yes |
| data\_vault\_config\_bucket | TF state GCS bucket for Vault configuration. | `string` | n/a | yes |
| data\_vault\_config\_bucket\_prefix | Folder for the GCS bucket for Vault configuration. | `string` | n/a | yes |
| environment | The deployment environment. | `string` | n/a | yes |
| grafana\_admin\_secret\_password\_key | Grafana admin password secret key. | `string` | n/a | yes |
| grafana\_admin\_secret\_user\_key | Grafana admin username secret key. | `string` | n/a | yes |
| grafana\_admin\_secret\_user\_value | Grafana admin username. | `string` | n/a | yes |
| impersonate\_account | The service account that TF used for Google provider. | `string` | n/a | yes |
| ollama\_secret\_name | Name of Ollama Keycloak Client secret | `string` | n/a | yes |
| opencost\_secret\_name | Name of OpenCost secret | `string` | n/a | yes |
| project\_id | Project ID. | `string` | n/a | yes |
| vault\_database\_sso\_tls\_secret\_name | Name of the secret where the Vault certificated is stored. | `string` | n/a | yes |
| vault\_database\_sso\_tls\_ttl | The time after which this certificate will no longer be valid. | `string` | n/a | yes |
| vault\_grafana\_admin\_secret\_name | The secret name of Kubernetes secret that contains Grafana admin user credentials. | `string` | n/a | yes |
| vault\_keycloak\_admin\_secret\_name | The secret name of Kubernetes secret that contains Keycloak admin user credentials. | `string` | n/a | yes |
| vault\_keycloak\_database\_secret\_name | The name of the Kubernetes secret where Keycloak database data is stored. | `string` | n/a | yes |
| vault\_keycloak\_metrics\_secret\_name | The name of the Kubernetes secret where Keycloak Metrics user data is stored. | `string` | n/a | yes |
| vault\_lobechat\_secret\_name | The secret name of Kubernetes secret that contains Lobe chat credentials. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| alertmanager\_secret\_name | Alertmanager Oauth2 proxy secret name. |
| database\_sso\_tls\_secret\_name | Name of the secret that contains the TLS for PostgreSQL in SSO namespace. |
| grafana\_admin\_secret\_name | Name of the secret that contains Grafana user admin credentials. |
| grafana\_admin\_secret\_password\_key | Secret key for Grafana admin password. |
| grafana\_admin\_secret\_user\_key | Secret key for Grafana admin username. |
| keycloak\_admin\_secret\_name | Name of the secret that contains Keycloak user admin credentials. |
| keycloak\_database\_secret\_keys | Secret key names for the database keycloak secret. |
| keycloak\_database\_secret\_name | Name of the secret that contains database data for Keycloak. |
| keycloak\_metrics\_database\_secret\_keys | Secret key names for the database keycloak metrics secret. |
| keycloak\_metrics\_secret\_name | Name of the secret that contains Keycloak Metrics user credentials. |
| lobechat\_secret\_name | Lobe chat credentials secret name. |
| ollama\_secret\_name | Ollama Oauth2 proxy secret name. |
| opencost\_secret\_name | OpenCost Oauth2 proxy secret name. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
