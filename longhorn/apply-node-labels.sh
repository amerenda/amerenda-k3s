#!/bin/bash

# Longhorn Node Labeling Script
# This script applies the necessary labels to configure Longhorn storage nodes

set -e

echo "🔧 Configuring Longhorn node labels..."

# Label storage nodes (Raspberry Pi nodes)
echo "📦 Labeling storage nodes..."
kubectl label node rpi5-0 longhorn.io/storage=true --overwrite
kubectl label node rpi5-1 longhorn.io/storage=true --overwrite

# Label excluded node (archlinux for Jellyfin)
echo "🚫 Labeling excluded node..."
kubectl label node archlinux longhorn.io/exclude-from-backup=true --overwrite

# Remove any existing storage labels from archlinux
kubectl label node archlinux longhorn.io/storage- || true

echo "✅ Node labeling complete!"
echo ""
echo "📊 Current node configuration:"
kubectl get nodes --show-labels | grep -E "(NAME|rpi5|archlinux)"

echo ""
echo "🎯 Longhorn will now:"
echo "   • Use rpi5-0 and rpi5-1 for storage"
echo "   • Exclude archlinux from storage operations"
echo "   • Create volumes with 2 replicas by default"
echo "   • Keep archlinux free for Jellyfin with GPU access"
