# © 2023 Translucent Computing Inc.
#
# Usage:
# - Use `make help` to list all available commands and their descriptions.
# - Adjust variables in the 'Configuration' section as needed.

# Configure shell
SHELL := /usr/bin/env bash

# Configuration - Developer Tools
REGISTRY_URL := gcr.io/cloud-foundation-cicd
DOCKER_IMAGE_DEVELOPER_TOOLS := cft/developer-tools
DOCKER_TAG_VERSION_DEVELOPER_TOOLS := 1.22.16

# Configuration - SSH Tunnel Variables
BUCKET_NAME := tc-tekstack-kps-terraform-state-bucket
STATE_FILE_PATH := bastion/prod/default.tfstate
OUTPUT_KEY := bastion_ssh_command
TUNNEL_PORT := 8888

# Display help message with descriptions for each target
.PHONY: help
help:
	@echo -e "\n\033[1mAvailable Commands:\033[0m"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Generate documentation
.PHONY: docker_generate_docs
docker_generate_docs: ## Generate Terraform docs
	docker run --rm -it \
		-v $(CURDIR):/workspace \
		$(REGISTRY_URL)/${DOCKER_IMAGE_DEVELOPER_TOOLS}:${DOCKER_TAG_VERSION_DEVELOPER_TOOLS} \
		/bin/bash -c 'source /usr/local/bin/task_helper_functions.sh && generate_docs'


# Enter docker container for local development
.PHONY: docker_run
docker_run: ## Enter docker container for local development
	docker run --rm -it \
		-e CFT_DISABLE_INIT_CREDENTIALS=yes \
		-v "$(CURDIR)":/workspace \
		$(REGISTRY_URL)/${DOCKER_IMAGE_DEVELOPER_TOOLS}:${DOCKER_TAG_VERSION_DEVELOPER_TOOLS} \
		/bin/bash

# SSH Tunnel Management
.PHONY: start_proxy
start_proxy: ## Start SSH Tunnel/Proxy
	@BUCKET_NAME=$(BUCKET_NAME) STATE_FILE_PATH=$(STATE_FILE_PATH) OUTPUT_KEY=$(OUTPUT_KEY) TUNNEL_PORT=$(TUNNEL_PORT) ./scripts/start_ssh_tunnel.sh

.PHONY: stop_proxy
stop_proxy: ## Stop SSH Tunnel/Proxy
	@TUNNEL_PORT=$(TUNNEL_PORT) ./scripts/stop_ssh_tunnel.sh
