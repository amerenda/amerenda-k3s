#!/bin/bash

# Tailscale setup script for K3s cluster
# This script sets up Tailscale with DNS routing to Pi-hole

set -e

echo "=== Setting up Tailscale VPN ==="
echo ""

# 1. Create namespace and deploy Tailscale
echo "1. Deploying Tailscale to K3s cluster..."
kubectl apply -f tailscale.yaml

# Wait for Tailscale to be ready
echo "Waiting for Tailscale to be ready..."
kubectl wait --for=condition=ready pod -l app=tailscale -n tailscale --timeout=60s

# 2. Get the auth URL
echo ""
echo "2. Getting Tailscale auth URL..."
AUTH_URL=$(kubectl logs -n tailscale deployment/tailscale | grep -o 'https://login.tailscale.com/admin/machines/[^"]*' | tail -1)

if [ -z "$AUTH_URL" ]; then
    echo "❌ Could not find auth URL. Please check Tailscale logs:"
    kubectl logs -n tailscale deployment/tailscale
    exit 1
fi

echo "✅ Found auth URL: $AUTH_URL"
echo ""
echo "3. Please complete the following steps:"
echo ""
echo "   📱 On your phone:"
echo "   1. Install Tailscale app from App Store/Google Play"
echo "   2. Sign in with your Tailscale account"
echo "   3. Connect to your network"
echo ""
echo "   🖥️  On your computer:"
echo "   1. Go to: $AUTH_URL"
echo "   2. Click 'Authorize' to approve this device"
echo "   3. Go to https://login.tailscale.com/admin/dns"
echo "   4. Add nameserver: 10.100.20.240 (your Pi-hole)"
echo "   5. Enable 'Override local DNS' for your phone"
echo ""
echo "   🔧 Configure Pi-hole for Tailscale:"
echo "   1. Go to Pi-hole admin: http://10.100.20.242"
echo "   2. Settings → DNS → Custom 1: 1.1.1.1"
echo "   3. Settings → DNS → Custom 2: 1.0.0.1"
echo "   4. This ensures Pi-hole can resolve external DNS"
echo ""
echo "   🏠 Access local services:"
echo "   - Home Assistant: http://homeassistant.amer.local"
echo "   - Pi-hole Admin: http://pihole.amer.local"
echo "   - Any other local services by their .amer.local names"
echo ""
echo "✅ Tailscale setup complete!"
echo ""
echo "Your phone will now:"
echo "✅ Use Pi-hole for DNS (blocks ads everywhere)"
echo "✅ Access local services by name"
echo "✅ Work from anywhere with internet"
