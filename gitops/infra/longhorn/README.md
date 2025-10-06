# Longhorn Setup for k3s on Raspberry Pi

This directory contains the Longhorn distributed storage setup for your k3s cluster running on Raspberry Pi devices.

## Overview

Longhorn provides distributed block storage with built-in replication, making it perfect for resilient shared storage across your Raspberry Pi nodes.

## Features

- **Distributed Storage**: Data replicated across multiple nodes
- **High Availability**: Pods can be scheduled on any node
- **Snapshots**: Built-in backup capabilities
- **Web UI**: Easy management and monitoring
- **ARM64 Support**: Optimized for Raspberry Pi

## Files

- `setup-longhorn.sh`: Installation script
- `longhorn-ui-lb.yaml`: LoadBalancer service for Longhorn UI
- `longhorn-config.yaml`: Longhorn configuration settings
- `apply-node-labels.sh`: Script to configure node labels
- `README.md`: This documentation

## Quick Start

1. **Install Longhorn**:
   ```bash
   chmod +x setup-longhorn.sh
   ./setup-longhorn.sh
   ```

2. **Configure node labels**:
   ```bash
   chmod +x apply-node-labels.sh
   ./apply-node-labels.sh
   ```

3. **Apply Longhorn settings**:
   ```bash
   kubectl apply -f longhorn-config.yaml
   ```

4. **Access the UI**:
   - **LoadBalancer (Recommended)**: http://longhorn.amer.local or http://longhorn.amer.home (IP: 10.100.20.243)
   - **Port-Forward (Alternative)**:
     ```bash
     kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80
     ```
     Then open http://localhost:8080 in your browser

3. **Update your applications** to use the `longhorn` storage class:
   ```yaml
   persistentVolumeClaim:
     enabled: true
     storageClass: longhorn
     accessModes: [ReadWriteMany]
     size: 1Gi
   ```

## Configuration

### Storage Class Settings

- **Default Replica Count**: 2 (data replicated across 2 nodes)
- **Access Mode**: ReadWriteMany (pods can be scheduled anywhere)
- **Reclaim Policy**: Delete (volumes deleted when PVC is deleted)

### Resource Limits

Optimized for Raspberry Pi with limited resources:
- **Manager**: 100m CPU, 128Mi memory
- **UI**: 50m CPU, 64Mi memory
- **Engine**: 50m CPU, 64Mi memory

## Usage Examples

### Pi-hole with Longhorn

Update your Pi-hole values.yaml:
```yaml
persistentVolumeClaim:
  enabled: true
  storageClass: longhorn
  accessModes: [ReadWriteMany]
  size: 1Gi
```

### Home Assistant with Longhorn

```yaml
persistence:
  enabled: true
  storageClass: longhorn
  accessModes: [ReadWriteMany]
  size: 8Gi
```

## Monitoring

### Check Longhorn Status
```bash
kubectl get pods -n longhorn-system
kubectl get storageclass
kubectl get pv
```

### View Longhorn Logs
```bash
kubectl logs -n longhorn-system -l app=longhorn-manager
kubectl logs -n longhorn-system -l app=longhorn-ui
```

## Troubleshooting

### Common Issues

1. **Pods not starting**: Check if Longhorn is ready
   ```bash
   kubectl get pods -n longhorn-system
   ```

2. **Storage not available**: Verify storage class
   ```bash
   kubectl get storageclass
   ```

3. **Replication issues**: Check node status in Longhorn UI

### Cleanup

To remove Longhorn:
```bash
kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/v1.6.0/deploy/longhorn.yaml
```

## Benefits for Your Setup

- **Pod Mobility**: Pi-hole and other services can run on any node
- **Data Resilience**: 2 replicas across different SD cards
- **Easy Migration**: Simple to move from local-path to Longhorn
- **Backup Ready**: Built-in snapshot capabilities
- **Resource Efficient**: Designed for edge computing

## Next Steps

1. Install Longhorn using the setup script
2. Update your applications to use the `longhorn` storage class
3. Configure replication settings in the Longhorn UI
4. Test storage by creating a test PVC
5. Migrate existing applications to Longhorn storage