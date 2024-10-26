# Kubernetes Tools Deployment Project

This project is a **blueprint** for deploying and managing various tools within a Kubernetes environment, with a focus on production readiness. It provides a structured approach using **Terragrunt**, **Makefile automation**, and **supporting scripts** to lay the foundation for a production system. However, as with any production environment, additional considerations and adaptations are required based on specific real-world requirements and issues.

## Important Considerations

This project serves as a **blueprint** for a production-ready setup but may not be fully runnable without additional configuration. Like any production deployment, you’ll need to adapt configurations, handle networking, and address security policies unique to your production environment.

### Production Readiness Tips

- **Adapt to Your Environment**: Customize variables and configurations based on your specific cloud provider, network setup, and security requirements.
- **Manage Real-World Constraints**: Be prepared to adjust deployments in response to performance requirements, fault tolerance, and scalability.
- **Monitoring and Observability**: Integrate monitoring tools to ensure that deployments are reliable and meet operational expectations.

## Getting Started

### Prerequisites

- `Terraform and Terragrunt`: Used to define and manage the infrastructure.
- `Helm`: Required for deploying the Kubernetes tools.
- `Google Cloud SDK` (optional): For managing SSH tunneling if deploying on GCP.

### Usage

1. **Setting Up SSH Tunneling** (if deploying on GCP):
      - Use `make start_proxy` to start the SSH tunnel to the bastion host, allowing secure access.
      - Use `make stop_proxy` to stop the SSH tunnel when no longer needed.
2. **Deploying Tools Across Environments**:
    - Navigate to the specific environment directory, such as `prod` under the desired tool (e.g., `external_secrets/environments/prod`).
    - Run the following Terragrunt command to deploy the resources for that environment:
  
      ```bash
      HTTPS_PROXY="http://127.0.0.1:8888" terragrunt apply
      ```

      - Set the `HTTPS_PROXY` environment variable as shown if the deployment requires SSH tunneling. Adjust the proxy address if a different port or address is configured.

## Terragrunt and Terraform Project Structure

This project leverages **Terragrunt** to manage and simplify the deployment of **Terraform** configurations across multiple environments. By structuring the project in this way, we can efficiently organize and reuse infrastructure code, making it easier to manage environment-specific configurations.

### Project Structure Overview

```plaintext
.
├── external_secrets                      # Primary tool directory
│   ├── environments                      # Environment-specific configurations for Terragrunt
│   │   ├── env.hcl                       # Common configuration across environments
│   │   ├── prod                          # Production environment directory
│   │   │   └── terragrunt.hcl            # Production-specific Terragrunt configuration
│   │   └── terragrunt.hcl                # Base Terragrunt configuration
│   └── infra                             # Terraform infrastructure definitions for external secrets
│       ├── main.tf                       # Main Terraform configuration
│       ├── variables.tf                  # Input variables for Terraform
│       └── values.yaml                   # Helm values for deployment
```

#### Key Components

1. **Environments Directory**:
   - Each tool has an `environments` directory containing environment-specific configurations, such as dev, staging, and prod.
   - `env.hcl`: Common configurations shared across all environments.
   - `terragrunt.hcl`: Base configuration for Terragrunt to manage and pass variables to Terraform.
   - `<environment>/terragrunt.hcl`: Specific Terragrunt configurations for each environment, enabling tailored settings for production, staging, or other setups.
2. **Infrastructure Directory**:
   - The `infra` directory holds the main Terraform configurations.
   - `main.tf`: The primary Terraform file defining resources and modules to deploy the tool.
   - `variables.tf` and `outputs.tf`: Input variables and output configurations for easy management and reuse.

#### Terragrunt Configuration

Each environment has its own `terragrunt.hcl` file, which points to the shared Terraform infrastructure code in the infra directory. This setup allows you to:

- `Reuse Infrastructure Code`: Keep shared infrastructure definitions centralized in infra, while using environment-specific configurations in environments.
- `Environment Isolation`: Maintain separate configurations and state management for each environment.
- `Easy Adaptation for Production Needs`: Update the environment-specific terragrunt.hcl files to manage production-specific settings, such as scaling, networking, and security.

This structure provides a scalable and modular way to manage multiple environments, making it easier to deploy, maintain, and update Kubernetes tools in a production-grade setup.

### Makefile Commands

The Makefile provides several automation commands to facilitate development and deployment. Use `make help` to see a list of available commands along with their descriptions.

- `make help`: Lists all available Makefile commands and their descriptions.
  
- `make docker_generate_docs`: Generates Terraform documentation within a Docker container. This command uses the specified developer tools image and mounts the current directory to `/workspace`.

- `make docker_run`: Starts an interactive Docker container for local development. It uses the developer tools image, mounting the current directory for easy access to project files.

- `make start_proxy`: Initiates an SSH tunnel to a bastion host for secure access, using settings from the Makefile. This is particularly useful for managing deployments on Google Cloud Platform (GCP).

- `make stop_proxy`: Stops the SSH tunnel that was initiated by `make start_proxy`, closing the secure access.

Additional targets may be added for specific tools and deployment needs.

## License

This project is licensed under the terms specified in the LICENSE file.

## Contributing

Contributions are welcome! Please review the contribution guidelines (if available) and submit pull requests for any changes.
