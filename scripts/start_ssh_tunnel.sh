#!/usr/bin/env bash

# This script is designed to establish an SSH tunnel/proxy to a Bastion host.
# It retrieves the SSH command from a Terraform state file stored in a GCS bucket.
# If an SSH tunnel is not already running, it starts a new one.

# Safety settings: exit on error, treat unset variables as an error,
# and make pipelines fail on first error
set -o errexit
set -o nounset
set -o pipefail

# Set Variables (fall back to default if not set)
: "${BUCKET_NAME:?Error: BUCKET_NAME is not set. Please set it in the Makefile.}"
: "${STATE_FILE_PATH:?Error: STATE_FILE_PATH is not set. Please set it in the Makefile.}"
OUTPUT_KEY="${OUTPUT_KEY:-bastion_ssh_command}" # Optional, defaults to bastion_ssh_command
TUNNEL_PORT="${TUNNEL_PORT:-8888}"               # Optional, defaults to 8888

# Function Definitions

# Check if a command exists
command_exists() {
  type "$1" &> /dev/null
}

# Main Execution

# Validate required tools
if ! command_exists gsutil || ! command_exists jq; then
  echo "Error: Required command(s) 'gsutil' and/or 'jq' are not installed." >&2
  exit 1
fi

echo "Checking SSH Bastion Tunnel/Proxy status..."

# Verify if an SSH tunnel is already running
if ! pgrep -f "L${TUNNEL_PORT}:127.0.0.1:${TUNNEL_PORT}" > /dev/null; then
  echo "No active SSH tunnel detected. Attempting to establish a new SSH tunnel."

  # Retrieve the SSH command from the Terraform state file in GCS
  if ! bastion_ssh_command=$(gsutil cat gs://${BUCKET_NAME}/${STATE_FILE_PATH} | jq -r ".outputs.${OUTPUT_KEY}.value"); then
    echo "Error: Unable to retrieve SSH command from Terraform state." >&2
    exit 1
  fi

  # Validate the structure of the SSH command
  if [[ ! $bastion_ssh_command == *"gcloud compute ssh"* ]]; then
    echo "Error: Retrieved command does not look like an SSH command." >&2
    exit 1
  fi

  # Execute the command
  echo "Establishing SSH tunnel to Bastion host..."
  eval "${bastion_ssh_command}"
  echo "SSH Tunnel/Proxy has been established on port ${TUNNEL_PORT}."
else
  echo "SSH tunnel is already active on port ${TUNNEL_PORT}. No action taken."
fi
