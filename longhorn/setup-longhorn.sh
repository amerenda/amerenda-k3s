#!/bin/bash

# Longhorn Setup Script for k3s on Raspberry Pi
# This script installs Longhorn distributed storage

set -e

echo "🚀 Installing Longhorn on k3s cluster..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl first."
    exit 1
fi

# Check if k3s is running
if ! kubectl get nodes &> /dev/null; then
    echo "❌ Cannot connect to k3s cluster. Please ensure k3s is running."
    exit 1
fi

echo "✅ k3s cluster is accessible"

# Create longhorn-system namespace if it doesn't exist
kubectl create namespace longhorn-system --dry-run=client -o yaml | kubectl apply -f -

echo "📦 Installing Longhorn..."

# Install Longhorn using the official manifest
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.6.0/deploy/longhorn.yaml

echo "⏳ Waiting for Longhorn to be ready..."

# Wait for Longhorn manager to be ready
kubectl wait --for=condition=ready pod -l app=longhorn-manager -n longhorn-system --timeout=300s

# Wait for Longhorn UI to be ready
kubectl wait --for=condition=ready pod -l app=longhorn-ui -n longhorn-system --timeout=300s

echo "✅ Longhorn installation completed!"

# Check the status
echo "📊 Longhorn Status:"
kubectl get pods -n longhorn-system

echo ""
echo "🌐 To access Longhorn UI:"
echo "kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80"
echo "Then open http://localhost:8080 in your browser"

echo ""
echo "📋 Next steps:"
echo "1. Update your applications to use 'longhorn' storage class"
echo "2. Configure replication settings in the Longhorn UI"
echo "3. Test storage by creating a test PVC"

echo ""
echo "🔧 Storage Class Configuration:"
echo "storageClass: longhorn"
echo "accessModes: [ReadWriteMany]"
