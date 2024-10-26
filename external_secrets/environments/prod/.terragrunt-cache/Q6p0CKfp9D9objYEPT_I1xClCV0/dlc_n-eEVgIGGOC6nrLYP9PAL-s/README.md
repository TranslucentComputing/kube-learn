<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cert\_duration | External DNS issuer cert duration. | `string` | n/a | yes |
| cert\_renew | External DNS issuer cert renewal. | `string` | n/a | yes |
| cert\_subject | Certificate subject | <pre>object({<br>    organizations = list(string)<br>    organizationalUnits = list(string)<br>  })</pre> | n/a | yes |
| chart\_release\_name | Helm chart release name | `string` | n/a | yes |
| chart\_version | Helm chart version to deploy. | `string` | n/a | yes |
| cluster\_location | Cluster zone or region. | `string` | n/a | yes |
| cluster\_name | Cluster name. | `string` | n/a | yes |
| data\_gke\_man\_bucket | TF state GCS bucket for GKE management | `string` | n/a | yes |
| data\_gke\_man\_bucket\_prefix | Folder for the GCS bucket for GKE management | `string` | n/a | yes |
| data\_prom\_stack\_bucket | TF state GCS bucket for Prom Stack deployment. | `string` | n/a | yes |
| data\_prom\_stack\_bucket\_prefix | Folder for the GCS bucket for Prom Stack deployment. | `string` | n/a | yes |
| enable\_metrics | Flag to metrics resource creation | `bool` | `false` | no |
| environment | The deployment environment. | `string` | n/a | yes |
| impersonate\_account | The service account that TF used for Google provider. | `string` | n/a | yes |
| project\_id | Project ID. | `string` | n/a | yes |
| replica\_count | Replica count for the main controller. | `number` | n/a | yes |
| replica\_count\_webhook | Replica count for the webhook. | `number` | n/a | yes |
| resources | Compute Resources required by the container. CPU/RAM requests/limits | <pre>object({<br>    requests = object({<br>      cpu    = string<br>      memory = string<br>    })<br>    limits = object({<br>      cpu    = string<br>      memory = string<br>    })<br>  })</pre> | n/a | yes |
| webhook\_resources | Compute Resources required by the container. CPU/RAM requests/limits | <pre>object({<br>    requests = object({<br>      cpu    = string<br>      memory = string<br>    })<br>    limits = object({<br>      cpu    = string<br>      memory = string<br>    })<br>  })</pre> | n/a | yes |

## Outputs

No outputs.

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->