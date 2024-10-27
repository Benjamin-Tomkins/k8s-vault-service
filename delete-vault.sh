#!/bin/bash

# Set the YAML file for the Vault deployment
VAULT_DEPLOYMENT_FILE="vault-deployment.yaml"

# Check if the YAML file exists
if [[ ! -f "$VAULT_DEPLOYMENT_FILE" ]]; then
  echo "Error: $VAULT_DEPLOYMENT_FILE not found!"
  exit 1
fi

# Stop active port forwarding on port 8200
echo "Stopping any active port forwarding on port 8200..."
PORT_FORWARD_PID=$(lsof -t -i:8200)
if [[ -n "$PORT_FORWARD_PID" ]]; then
  kill "$PORT_FORWARD_PID"
  echo "Port forwarding on port 8200 stopped."
fi

# Delete Vault resources and wait for completion
echo "Deleting Vault resources..."
kubectl delete -f "$VAULT_DEPLOYMENT_FILE" --grace-period=0 --force --wait

echo "Vault resources have been successfully stopped and deleted."
