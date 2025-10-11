# amerenda-k3s

A complete k3s Kubernetes cluster setup for Raspberry Pi with GitOps automation using ArgoCD.

## 🏗️ Architecture

- **k3s HA Cluster**: Multi-controller setup with etcd backend
- **GitOps**: ArgoCD manages all deployments from Git
- **Storage**: Longhorn distributed storage with automated backups
- **Networking**: Flannel CNI, MetalLB load balancer, Tailscale VPN, Pi-hole DNS
- **Home Automation**: Home Assistant with Eufy integrations
- **Secrets Management**: External Secrets Operator with Bitwarden

## 🚀 Quick Start

### Prerequisites

1. **Raspberry Pi Setup**:
   - Install Raspberry Pi OS on 4+ devices
   - Configure static IPs (see `ansible/inventory.ini`)
   - Set up SSH access with your key

2. **Local Machine**:
   - Ansible installed
   - kubectl installed
   - SSH access to all Pi devices

### Setup Process

1. **Configure Inventory**:
   ```bash
   # Edit ansible/inventory.ini with your Pi IPs
   vim ansible/inventory.ini
   ```

2. **Set k3s Token**:
   ```bash
   # Generate a secure token
   export K3S_TOKEN=$(openssl rand -hex 32)
   ```

3. **Run the Playbook**:
   ```bash
   # This sets up everything: etcd, k3s, ArgoCD, and bootstraps GitOps
   ansible-playbook -i ansible/inventory.ini ansible/setup-k3s-cluster.yml -e k3s_token=$K3S_TOKEN
   ```

4. **Bootstrap Bitwarden Secret**:
   ```bash
   # Get your Bitwarden access token and update the secret
   vim bootstrap/bitwarden-credentials-secret.yaml
   kubectl apply -f bootstrap/bitwarden-credentials-secret.yaml
   ```

## 📁 Directory Structure

- **`ansible/`**: Ansible playbooks for cluster setup and management
- **`bootstrap/`**: Initial configuration files (ArgoCD, Bitwarden secrets)
- **`gitops/`**: GitOps manifests managed by ArgoCD
  - **`apps/`**: Application deployments (Home Assistant, Pi-hole, Tailscale)
  - **`infra/`**: Infrastructure components (Longhorn, External Secrets, DNS)

## 🔧 What Gets Deployed

### Deployment Order (Sync Waves)
- **Wave 0**: Flannel CNI (critical for networking)
- **Wave 1**: cert-manager (TLS certificates)
- **Wave 2**: External Secrets (secret management)
- **Wave 3**: Longhorn (storage, needs secrets)
- **Wave 4**: DNS (needs TSIG secrets)
- **Wave 5**: Applications (Home Assistant, Pi-hole, Tailscale)

### Infrastructure
- **k3s**: Lightweight Kubernetes with etcd HA
- **ArgoCD**: GitOps continuous delivery
- **Flannel**: Container Network Interface (CNI) for pod networking
- **Longhorn**: Distributed block storage with GCS backups (requires open-iscsi)
- **External Secrets**: Bitwarden integration for secrets
- **MetalLB**: Load balancer for services
- **cert-manager**: TLS certificate management
- **DNS**: BIND9 with External DNS for dynamic updates

### Applications
- **Home Assistant**: Smart home automation with Eufy integrations
- **Pi-hole**: Network-wide ad blocking
- **Tailscale**: Secure mesh VPN

## 🛠️ Management

### Access ArgoCD
```bash
# Port forward to access ArgoCD UI
kubectl port-forward svc/argocd-server 8080:80
# Open http://localhost:8080
```

### Check Cluster Status
```bash
kubectl get nodes
kubectl get pods -A
kubectl get applications -A
```

### Update Applications
```bash
# All changes are managed via Git
git add .
git commit -m "Update configuration"
git push
# ArgoCD automatically syncs changes
```

## 📚 Documentation

- **`ansible/README.md`**: Ansible playbook documentation
- **`gitops/README.md`**: GitOps configuration guide
- **`bootstrap/`**: Initial setup instructions

## 🔐 Security

- All secrets managed via Bitwarden
- TLS certificates automatically provisioned
- Network policies and RBAC configured
- Regular automated backups to GCS

## 🆘 Troubleshooting

### Common Issues

**Longhorn Pods Crashing**
- **Symptom**: `longhorn-manager` pods in CrashLoopBackOff
- **Cause**: Missing `open-iscsi` package on nodes
- **Fix**: Install open-iscsi on affected nodes:
  ```bash
  sudo apt update && sudo apt install -y open-iscsi
  kubectl delete pod <failing-pod-name>
  ```

**Network Issues (ContainerCreating pods)**
- **Symptom**: Pods stuck in ContainerCreating state
- **Cause**: Missing Flannel CNI daemonset
- **Fix**: Flannel is deployed via GitOps in sync-wave 0. Check ArgoCD applications.

**External Secrets Not Working**
- **Symptom**: `ClusterSecretStore not found` or TLS errors
- **Cause**: Missing Bitwarden credentials or TLS certificate issues
- **Fix**: Ensure `bitwarden-credentials` secret is applied and TLS certificates are valid.

See individual component READMEs in each directory for specific troubleshooting guides.

## 📝 License

MIT License - see LICENSE file for details.
