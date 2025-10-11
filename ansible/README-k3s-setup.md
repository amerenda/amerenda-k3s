# k3s Multi-Controller Cluster Setup

This directory contains Ansible playbooks to set up a high-availability k3s cluster with etcd backend on Raspberry Pi devices.

## Architecture

- **Controllers**: rpi5-0, rpi5-1, rpi4-0 (3 controllers for HA)
- **Longhorn-only**: rpi3-0 (dedicated storage node with taints)
- **Backend**: etcd for distributed state storage
- **User**: alex (non-root user)

## Prerequisites

1. **SSH Key**: Ensure `~/.ssh/alex_id_ed25519` exists
2. **Network**: All nodes must be able to communicate on ports 6443, 2379, 2380
3. **Existing Cluster**: This assumes you have an existing k3s cluster on rpi5-0 and rpi5-1

## Setup Process

### 1. Update Configuration

Edit `group_vars/k3s.yml` and set a secure token:
```yaml
k3s_token: "your-secure-token-here"  # CHANGE THIS!
```

### 2. Run the Setup

```bash
# Step 1: Setup the k3s cluster with etcd
ansible-playbook -i inventory.ini setup-k3s-cluster.yml -e k3s_token=your-secure-token

# Step 2: Configure post-setup (taints, labels, etc.)
ansible-playbook -i inventory.ini post-k3s-setup.yml
```

### 3. Verify Setup

```bash
# Check cluster status
kubectl --kubeconfig=k3s-kubeconfig.yaml get nodes -o wide

# Check Longhorn-only node taints
kubectl --kubeconfig=k3s-kubeconfig.yaml describe node rpi3-0
```

## What This Setup Does

### Controllers (rpi5-0, rpi5-1, rpi4-0)
- Installs k3s server with etcd backend
- Configures HA with 3 controllers
- Sets up proper networking and TLS
- Enables etcd snapshots every 6 hours
- Configures resource limits for Pi hardware

### Longhorn-only Node (rpi3-0)
- Installs k3s agent
- Adds taints to prevent general workloads
- Labels for Longhorn storage
- Optimized for storage workloads

## Important Notes

⚠️ **Existing Cluster**: This setup assumes you have an existing k3s cluster. The playbook will:
- Preserve existing data on rpi5-0 and rpi5-1
- Add rpi4-0 as a new controller
- Convert the cluster to use etcd backend

## Configuration Files

- `inventory.ini`: Node inventory with proper grouping
- `setup-k3s-cluster.yml`: Main cluster setup playbook
- `post-k3s-setup.yml`: Post-installation configuration
- `templates/`: k3s configuration templates
- `group_vars/k3s.yml`: Cluster configuration variables

## Troubleshooting

### Check k3s Status
```bash
# On each controller
sudo systemctl status k3s

# Check logs
sudo journalctl -u k3s -f
```

### Verify etcd
```bash
# Check etcd status
sudo systemctl status etcd
```

### Check Node Taints
```bash
kubectl describe node rpi3-0 | grep -A 5 Taints
```

## Next Steps

After successful setup:
1. Deploy Longhorn using your GitOps configuration
2. Verify all nodes are ready and properly configured
3. Test failover by stopping one controller
4. Monitor etcd health and snapshots
