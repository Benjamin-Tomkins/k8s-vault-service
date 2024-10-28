#!/bin/bash

clear

# Function to output messages with timestamps
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') $1"
}

# Set the YAML file for the Vault deployment
VAULT_DEPLOYMENT_FILE="vault-deployment.yaml"

# Check if the YAML file exists
if [[ ! -f "$VAULT_DEPLOYMENT_FILE" ]]; then
  log "Error: $VAULT_DEPLOYMENT_FILE not found!"
  exit 1
fi

log "Creating Vault ConfigMap and Deployment..."
kubectl apply -f "$VAULT_DEPLOYMENT_FILE"

# Confirm creation
if [ $? -eq 0 ]; then
  log "Vault resources have been successfully created."
else
  log "Failed to create Vault resources."
  exit 1
fi

# Wait for the Vault pod to be ready
log "Waiting for Vault pod to be ready..."
kubectl wait --for=condition=available deployment/vault-dev --timeout=30s

if [ $? -ne 0 ]; then
  log "Vault pod did not become ready in time."
  exit 1
fi

# Start port-forwarding to access Vault, suppressing output
log "Starting port-forwarding to access Vault on http://127.0.0.1:8200..."
kubectl port-forward deployment/vault-dev 8200:8200 >/dev/null 2>&1 &
PORT_FORWARD_PID=$!

# Trap any errors to terminate port-forwarding if the script fails
trap 'log "An error occurred. Terminating port-forwarding..."; kill $PORT_FORWARD_PID' ERR

# Wait briefly to ensure port-forwarding has started
sleep 3

# Optional: Wait for the initialization Job to complete
log "Waiting for Vault initialization Job to complete..."
kubectl wait --for=condition=complete job/vault-init-job --timeout=60s

if [ $? -eq 0 ]; then
  log "Vault initialization Job completed successfully."
  # Log concise access message
  echo ""
  log "Vault UI is available at http://127.0.0.1:8200 with a root token value: 'root'"
  log "To stop the service use ./delete-vault.sh"
else
  log "Vault initialization Job did not complete in time."
  exit 1
fi

# Remove the error trap on successful completion
trap - ERR

# The script exits here and port-forwarding will be active until manually stopped
