#!/bin/bash

BASTION_RG=""
BASTION_NAME=""
TARGET_IP_ADDRESSES=("10.0.0.4" "10.0.0.5")
LOCAL_PORT=10001
TARGET_PORT=22

# Function to kill all background processes
cleanup() {
    echo "Terminating background processes..."
    kill 0
    exit
}

# Trap SIGINT (Ctrl+C) and call the cleanup function
trap cleanup SIGINT

# Connect to all 5 VMs (background process)
for IP in "${TARGET_IP_ADDRESSES[@]}"; do
    az network bastion tunnel --name "${BASTION_NAME}" \
        --resource-group "${BASTION_RG}" \
        --target-ip-address "${IP}" \
        --resource-port "${TARGET_PORT}" \
        --port "${LOCAL_PORT}" &
    LOCAL_PORT=$((LOCAL_PORT + 1))
done

# Wait for all background processes to finish
wait