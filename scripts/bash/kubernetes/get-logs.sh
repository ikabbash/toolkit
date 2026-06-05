#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Check if at least one argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <namespace1> [namespace2 ...] | all"
    exit 1
fi

# Define base directory name with timestamp
DATE=$(date +"%Y-%m-%d_%H-%M")
BASE_DIR="kube-logs-${DATE}"

# Create base directory
mkdir -p "$BASE_DIR"

# Determine target namespaces
if [ "$1" = "all" ]; then
    NAMESPACES=$(kubectl get ns --no-headers -o custom-columns=":metadata.name")
else
    NAMESPACES="$@"
fi

# Loop through each namespace
for NAMESPACE in $NAMESPACES; do

    # Skip and warn if the namespace does not exist
    if ! kubectl get ns "$NAMESPACE" &>/dev/null; then
        echo "Warning: namespace '$NAMESPACE' does not exist, skipping..."
        continue
    fi

    NS_DIR="${BASE_DIR}/${NAMESPACE}"
    mkdir -p "$NS_DIR"

    # Get all pod names in the namespace
    PODS=$(kubectl get pods -n "$NAMESPACE" --no-headers -o custom-columns=":metadata.name")

    # Loop through each pod and save logs
    for POD in $PODS; do
        echo "Fetching logs for pod: $POD in namespace: $NAMESPACE"
        kubectl logs "$POD" -n "$NAMESPACE" --timestamps > "$NS_DIR/$POD.log"
    done
done

echo "Logs saved in $BASE_DIR/"