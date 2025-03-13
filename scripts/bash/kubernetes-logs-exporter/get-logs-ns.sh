#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Check if namespace argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <namespace>"
    exit 1
fi

NAMESPACE="$1"
DATE=$(date +"%Y-%m-%d_%H-%M")
DIR="${NAMESPACE}-ns-logs-${DATE}"

# Create the directory
mkdir -p "$DIR"

# Get all pod names in the namespace
PODS=$(kubectl get pods -n "$NAMESPACE" --no-headers -o custom-columns=":metadata.name")

# Loop through each pod and save logs
for POD in $PODS; do
    echo "Fetching logs for pod: $POD"
    kubectl logs "$POD" -n "$NAMESPACE" --timestamps > "$DIR/$POD.log"
done

echo "Logs saved in $DIR/"
