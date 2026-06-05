#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Define base directory name with timestamp
DATE=$(date +"%d-%m-%Y_%H-%M")
BASE_DIR="kube-logs-${DATE}"

# Create base directory
mkdir -p "$BASE_DIR"

# Get all namespaces
NAMESPACES=$(kubectl get ns --no-headers -o custom-columns=":metadata.name")

# Loop through each namespace
for NAMESPACE in $NAMESPACES; do
    NS_DIR="${BASE_DIR}/${NAMESPACE}"
    mkdir -p "$NS_DIR"

    # Get all pods in the namespace
    PODS=$(kubectl get pods -n "$NAMESPACE" --no-headers -o custom-columns=":metadata.name")

    # Loop through each pod and save logs
    for POD in $PODS; do
        echo "Fetching logs for pod: $POD in namespace: $NAMESPACE"
        kubectl logs "$POD" -n "$NAMESPACE" --timestamps > "$NS_DIR/$POD.log"
    done
done

echo "Logs saved in $BASE_DIR/"

