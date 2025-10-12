# Ansible Automation for k3s Cluster

This directory contains Ansible playbooks for setting up and managing a k3s Kubernetes cluster on Raspberry Pi devices with GitOps automation.

## 🚀 Quick Start

### Prerequisites
- Ansible 2.16+ installed
- SSH access to all Raspberry Pi devices
- Static IPs configured on Pi devices
- SSH key pair for authentication

### 1. Initial Pi Setup
```bash
# Prepare Pi devices for k3s and Longhorn
ansible-playbook -i inventory.ini setup-rpi.yml
```

### 2. k3s Cluster Setup
```bash
# Set k3s token
export K3S_TOKEN=$(openssl rand -hex 32)

# Deploy k3s HA cluster with etcd, ArgoCD, and GitOps bootstrap
ansible-playbook -i inventory.ini setup-k3s-cluster.yml -e k3s_token=$K3S_TOKEN
```

### 3. Post-Setup Configuration
```bash
# Apply node taints and labels for Longhorn
ansible-playbook -i inventory.ini post-k3s-setup.yml
```

## 📋 Playbooks Overview

### `setup-rpi.yml` - Pi Device Preparation
- **System Updates**: Updates packages and installs dependencies
- **Longhorn Prerequisites**: Configures iSCSI and required kernel modules
- **SSH Setup**: Configures SSH access and keys
- **Network Configuration**: Sets up DNS and network settings

### `setup-k3s-cluster.yml` - Main Cluster Setup
- **k3s Installation**: Deploys k3s with etcd HA backend
- **Multi-Controller**: Sets up multiple controller nodes
- **ArgoCD Installation**: Installs ArgoCD via Helm
- **GitOps Bootstrap**: Applies root-app.yaml to start GitOps workflow
- **kubeconfig Management**: Copies and configures kubeconfig locally
- **Longhorn Storage**: Automatically labels nodes for Longhorn storage
- **open-iscsi**: Installs required dependencies for Longhorn

### `post-k3s-setup.yml` - Post-Installation Configuration
- **Node Taints**: Applies storage-only taints to designated nodes
- **Node Labels**: Labels nodes for Longhorn replica scheduling
- **Cluster Verification**: Ensures all nodes are ready

## 📁 Files Structure

```
ansible/
├── inventory.ini                    # Host inventory with Pi IPs
├── group_vars/
│   ├── k3s.yml                     # k3s cluster configuration
│   └── rpi.yml                     # Pi-specific variables
├── templates/
│   ├── k3s.service.j2              # k3s systemd service template
│   ├── k3s-server-config.yaml.j2   # k3s server configuration
│   └── k3s-agent-config.yaml.j2    # k3s agent configuration
├── setup-rpi.yml                   # Pi device preparation
├── setup-k3s-cluster.yml           # Main cluster setup
├── post-k3s-setup.yml              # Post-installation configuration
└── README.md                       # This file
```

## ⚙️ Configuration

### Longhorn Storage Control
Control which nodes participate in Longhorn storage:

```bash
# Include all nodes in storage (default)
ansible-playbook -i inventory.ini setup-k3s-cluster.yml

# Exclude specific node from storage
ansible-playbook -i inventory.ini setup-k3s-cluster.yml -e longhorn_storage_enabled=false --limit rpi5-0

# Exclude all controllers from storage
ansible-playbook -i inventory.ini setup-k3s-cluster.yml -e longhorn_storage_enabled=false --limit controllers
```

### Inventory Setup
Edit `inventory.ini` with your Pi IP addresses:
```ini
[controllers]
rpi5-0 ansible_host=10.100.20.10
rpi5-1 ansible_host=10.100.20.11
rpi4-0 ansible_host=10.100.20.12

[longhorn_storage]
rpi3-0 ansible_host=10.100.20.13
```

### k3s Configuration
Edit `group_vars/k3s.yml`:
```yaml
# k3s version
k3s_version: "v1.33.5+k3s1"

# Network configuration
cluster_cidr: "10.42.0.0/16"
service_cidr: "10.43.0.0/16"

# Optional: Resize root filesystem
resize_rootfs: true
```

## 🏷️ Playbook Tags

Run specific parts of the playbooks:
```bash
# Pi preparation tags
ansible-playbook -i inventory.ini setup-rpi.yml --tags packages
ansible-playbook -i inventory.ini setup-rpi.yml --tags longhorn
ansible-playbook -i inventory.ini setup-rpi.yml --tags ssh

# k3s cluster tags
ansible-playbook -i inventory.ini setup-k3s-cluster.yml --tags k3s
ansible-playbook -i inventory.ini setup-k3s-cluster.yml --tags argocd
ansible-playbook -i inventory.ini setup-k3s-cluster.yml --tags dns
```

## ✅ Verification

### Check Cluster Status
```bash
# Verify k3s is running
kubectl get nodes
kubectl get pods -A

# Check ArgoCD
kubectl get pods -l app.kubernetes.io/name=argocd-server
kubectl get applications -A
```

### Verify Longhorn Prerequisites
```bash
# Check iSCSI service
ansible -i inventory.ini rpi -m shell -a "systemctl status iscsid"

# Check kernel modules
ansible -i inventory.ini rpi -m shell -a "lsmod | grep iscsi"
```

## 🔧 Advanced Usage

### Replace Existing Cluster
```bash
# WARNING: This will destroy existing cluster data
ansible-playbook -i inventory.ini setup-k3s-cluster.yml -e k3s_token=$K3S_TOKEN -e replace_cluster=true
```

### Filesystem Resize
```bash
# Enable automatic root filesystem resize
ansible-playbook -i inventory.ini setup-k3s-cluster.yml -e k3s_token=$K3S_TOKEN -e resize_rootfs=true
```

## 🆘 Troubleshooting

### Common Issues

**Token Mismatch Error**:
```bash
# Get correct token from first controller
ssh rpi5-0 "sudo cat /var/lib/rancher/k3s/server/token"
export K3S_TOKEN="<correct-token>"
```

**k3s Service Fails**:
```bash
# Check k3s logs
ssh rpi5-0 "journalctl -xeu k3s.service"

# Check for missing dependencies
ssh rpi5-0 "systemctl status k3s"
```

**ArgoCD Installation Fails**:
```bash
# Check Helm repository
helm repo list

# Check kubeconfig
kubectl config current-context
kubectl get nodes
```

### Network Issues
- Ensure static IPs are configured on all Pi devices
- Check DNS resolution: `nslookup 1.1.1.1`
- Verify SSH connectivity: `ansible -i inventory.ini rpi -m ping`
