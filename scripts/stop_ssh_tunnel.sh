#!/usr/bin/env bash

# This script safely stops an SSH tunnel/proxy to a Bastion host.
# It searches for an active SSH tunnel on a specified port (default 8888)
# and attempts to terminate it gracefully, with a force-stop as a fallback.
#
# Copyright © 2023 Translucent Computing Inc.

# Safety settings: exit on error, treat unset variables as an error,
# and make pipelines fail on first error
set -o errexit
set -o nounset
set -o pipefail

# Configuration - Tunnel Port (optional environment variable)
TUNNEL_PORT="${TUNNEL_PORT:-8888}"

# Main Execution

echo "Checking for active SSH Bastion Tunnel/Proxy on port ${TUNNEL_PORT}..."

# Find the process ID (PID) of the SSH tunnel
pid=$(pgrep -f L${TUNNEL_PORT}:127.0.0.1:${TUNNEL_PORT})

# Check if an SSH tunnel is running on the specified port
if [[ -n "$pid" ]]; then
  echo "Detected a running SSH tunnel (PID: $pid). Attempting to stop it gracefully..."

  # Send a SIGTERM first, allowing the process to terminate gracefully
  kill "$pid"

  # Wait a bit to see if the process terminates
  sleep 2

  # Check if the process is still running and force-stop if necessary
  if kill -0 "$pid" 2> /dev/null; then
    echo "SSH tunnel did not terminate gracefully; attempting forced stop."
    kill -9 "$pid"
  fi

  echo "SSH tunnel on port ${TUNNEL_PORT} has been stopped."
else
  echo "No active SSH tunnel detected on port ${TUNNEL_PORT}. Nothing to stop."
fi
