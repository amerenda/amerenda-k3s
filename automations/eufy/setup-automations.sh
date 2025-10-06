#!/bin/bash
# Setup script for Eufy automations with ConfigMaps
# This script applies all the automation ConfigMaps and updates Home Assistant

set -euo pipefail

NAMESPACE="home-assistant"
AUTOMATION_DIR="/home/alex/projects/amerenda-k3s/automations/eufy"

echo "🚀 Setting up Eufy automations with ConfigMaps..."

# Apply all ConfigMaps
echo "📦 Applying ConfigMaps..."
kubectl apply -f "$AUTOMATION_DIR/.configmaps/human-detection-configmap.yaml"
kubectl apply -f "$AUTOMATION_DIR/.configmaps/pet-detection-configmap.yaml"
kubectl apply -f "$AUTOMATION_DIR/.configmaps/privacy-mode-configmap.yaml"
kubectl apply -f "$AUTOMATION_DIR/.configmaps/helper-entities-configmap.yaml"
kubectl apply -f "$AUTOMATION_DIR/.configmaps/dashboard-cards-configmap.yaml"

echo "✅ ConfigMaps applied successfully!"

# Update Home Assistant deployment
echo "🔄 Updating Home Assistant deployment..."
kubectl apply -f "/home/alex/projects/amerenda-k3s/home-assistant/home-assistant.yaml"

echo "⏳ Waiting for Home Assistant to restart..."
kubectl rollout status deployment/homeassistant -n "$NAMESPACE" --timeout=300s

echo "🎉 Setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Go to Home Assistant → Settings → Devices & Services"
echo "2. Find your Eufy Security integration"
echo "3. Update entity names in the automation files if needed"
echo "4. Add helper entities to your configuration.yaml:"
echo "   kubectl exec -it deployment/homeassistant -n $NAMESPACE -- cat /config/automations/helper-entities.yaml"
echo ""
echo "🔧 To edit automation files:"
echo "kubectl edit configmap eufy-human-detection-automation -n $NAMESPACE"
echo "kubectl edit configmap eufy-pet-detection-automation -n $NAMESPACE"
echo "kubectl edit configmap eufy-privacy-mode-automation -n $NAMESPACE"
echo ""
echo "📊 To view ConfigMaps:"
echo "kubectl get configmaps -n $NAMESPACE | grep eufy"
