#!/bin/bash
# ConfigMap Generator for Eufy Automations
# This script generates ConfigMaps from the automation files

set -euo pipefail

NAMESPACE="home-assistant"
AUTOMATION_DIR="/home/alex/projects/amerenda-k3s/automations/eufy"

echo "Generating ConfigMaps for Eufy automations..."

# Function to create ConfigMap from file
create_configmap() {
    local file_path="$1"
    local configmap_name="$2"
    local key_name="$3"
    
    if [ ! -f "$file_path" ]; then
        echo "Warning: File $file_path not found, skipping..."
        return
    fi
    
    echo "Creating ConfigMap: $configmap_name"
    
    # Create ConfigMap from file
    kubectl create configmap "$configmap_name" \
        --from-file="$key_name=$file_path" \
        --namespace="$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
}

# Create ConfigMaps for automation files
create_configmap "$AUTOMATION_DIR/human-detection-automation.yaml" "eufy-human-detection-automation" "human-detection-automation.yaml"
create_configmap "$AUTOMATION_DIR/pet-detection-automation.yaml" "eufy-pet-detection-automation" "pet-detection-automation.yaml"
create_configmap "$AUTOMATION_DIR/privacy-mode-automation.yaml" "eufy-privacy-mode-automation" "privacy-mode-automation.yaml"
create_configmap "$AUTOMATION_DIR/helper-entities.yaml" "eufy-helper-entities" "helper-entities.yaml"
create_configmap "$AUTOMATION_DIR/dashboard-cards.yaml" "eufy-dashboard-cards" "dashboard-cards.yaml"

echo "ConfigMaps created successfully!"
echo ""
echo "To apply all ConfigMaps:"
echo "kubectl apply -f $AUTOMATION_DIR/*-configmap.yaml"
echo ""
echo "To view ConfigMaps:"
echo "kubectl get configmaps -n $NAMESPACE | grep eufy"
echo ""
echo "To edit a ConfigMap:"
echo "kubectl edit configmap <configmap-name> -n $NAMESPACE"
