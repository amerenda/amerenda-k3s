# GitOps Configuration

This directory contains the GitOps manifests managed by ArgoCD for your k3s cluster. All infrastructure and applications are defined here and automatically deployed.

## 🚀 Deployment Order (Sync Waves)

Applications are deployed in a specific order using ArgoCD sync waves:

- **Wave 0**: Flannel CNI (critical for networking)
- **Wave 1**: cert-manager (TLS certificates)  
- **Wave 2**: External Secrets (secret management)
- **Wave 3**: Longhorn (storage, needs secrets)
- **Wave 4**: DNS (needs TSIG secrets)
- **Wave 5**: Applications (Home Assistant, Pi-hole, Tailscale)

## 📁 Directory Structure

```
gitops/
├── root-app.yaml                 # ArgoCD App-of-Apps root application
├── apps/                         # Application deployments
│   ├── pihole/                   # Pi-hole DNS server
│   │   ├── externalsecret.yaml   # Bitwarden integration
│   │   └── values.yaml           # Helm values
│   ├── home-assistant/           # Home Assistant
│   │   ├── automations/          # Eufy automation configs
│   │   ├── configmap.yaml        # Home Assistant config
│   │   ├── home-assistant.yaml   # Deployment & Service
│   │   ├── namespace.yaml         # Namespace definition
│   │   └── storage.yaml          # Longhorn PVC
│   └── tailscale/                # Tailscale VPN
│       ├── deployment.yaml        # Tailscale deployment
│       ├── externalsecret.yaml   # Auth key from Bitwarden
│       ├── namespace.yaml        # Namespace definition
│       ├── pdb.yaml             # Pod Disruption Budget
│       └── secret.yaml           # Placeholder secret
├── infra/                         # Infrastructure components
│   ├── longhorn/                 # Distributed storage
│   │   ├── backups/              # Backup configuration
│   │   │   ├── externalsecret.yaml  # GCS credentials
│   │   │   └── recurringjob.yaml    # Backup schedule
│   │   ├── values.yaml           # Longhorn Helm values
│   │   └── README.md             # Longhorn documentation
│   ├── external-secrets/         # Secret management
│   │   ├── templates/            # Custom templates
│   │   ├── values.yaml           # Helm values
│   │   └── README.md             # Documentation
│   ├── metallb/                  # Load balancer
│   │   ├── templates/            # IP pool configuration
│   │   └── values.yaml           # Helm values
│   ├── cert-manager/             # TLS certificates
│   │   ├── values.yaml           # Helm values
│   │   └── README.md             # Documentation
│   ├── dns/                      # BIND9 DNS server
│   │   ├── configmap.yaml        # Zone configuration
│   │   ├── deployment.yaml       # BIND9 deployment
│   │   ├── externalsecret.yaml   # TSIG key from Bitwarden
│   │   ├── service.yaml          # DNS service
│   │   └── tsig-formatter.yaml   # TSIG key formatter
│   └── external-dns/             # Dynamic DNS updates
│       ├── values.yaml           # Helm values
│       └── README.md             # Documentation
└── README.md                     # This file
```

## 🚀 How It Works

### App-of-Apps Pattern
The `root-app.yaml` defines multiple ArgoCD Applications that automatically deploy:

1. **Infrastructure Applications**:
   - **Longhorn**: Distributed storage with GCS backups
   - **External Secrets**: Bitwarden integration for secrets
   - **MetalLB**: Load balancer for services
   - **cert-manager**: Automatic TLS certificates
   - **DNS**: BIND9 with External DNS for dynamic updates
   - **Monitoring**: Prometheus, Grafana, AlertManager

2. **Application Services**:
   - **Pi-hole**: Network-wide ad blocking
   - **Home Assistant**: Smart home automation with Eufy
   - **Tailscale**: Secure mesh VPN

### GitOps Workflow
1. **Commit Changes**: Edit manifests in this directory
2. **Push to Git**: Changes are pushed to the repository
3. **ArgoCD Sync**: ArgoCD automatically detects changes
4. **Deploy Updates**: Applications are updated automatically
5. **Monitor Status**: Check ArgoCD UI for deployment status

## 📋 Application Management

### Infrastructure Components (`infra/`)
- **Longhorn**: Distributed block storage with automated GCS backups
- **External Secrets**: Bitwarden integration for secure secret management
- **MetalLB**: Load balancer for exposing services
- **cert-manager**: Automatic TLS certificate provisioning
- **DNS**: BIND9 server with External DNS for dynamic updates
- **Monitoring**: Prometheus, Grafana, and AlertManager stack

### Application Services (`apps/`)
- **Pi-hole**: Network-wide DNS filtering and ad blocking
- **Home Assistant**: Smart home automation with Eufy integrations
- **Tailscale**: Secure mesh VPN for remote access

### Adding New Applications
1. **Create Directory**: Add new directory under `apps/` or `infra/`
2. **Add Manifests**: Create Kubernetes manifests (Deployment, Service, etc.)
3. **Update root-app.yaml**: Add new ArgoCD Application definition
4. **Commit & Push**: Changes are automatically deployed
5. **Monitor**: Check ArgoCD UI for deployment status

## 🌐 Access & Management

### ArgoCD UI Access
```bash
# Port forward to access ArgoCD UI
kubectl port-forward svc/argocd-server 8080:80
# Open http://localhost:8080

# Or access via LoadBalancer (if DNS configured)
# http://argocd.amer.home
```

### Application URLs
- **ArgoCD**: `http://argocd.amer.home` (port-forward: `localhost:8080`)
- **Longhorn**: `http://longhorn.amer.home` (port-forward: `localhost:8080`)
- **Pi-hole**: `http://pihole.amer.home` (port-forward: `localhost:8080`)
- **Home Assistant**: `http://homeassistant.amer.home` (port-forward: `localhost:8080`)

### Check Application Status
```bash
# View all ArgoCD applications
kubectl get applications -A

# Check specific application
kubectl describe application <app-name>

# View application logs
kubectl logs -l app.kubernetes.io/name=argocd-server
```

## 🔐 Security Features

- **External Secrets**: All secrets managed via Bitwarden
- **RBAC**: Role-based access control configured
- **Network Policies**: Secure pod-to-pod communication
- **TLS Certificates**: Automatic certificate provisioning
- **Tailscale Integration**: Secure remote access

## 🆘 Troubleshooting

### Common Issues

**Application Not Syncing**:
```bash
# Check ArgoCD application status
kubectl get applications -A
kubectl describe application <app-name>

# Check ArgoCD logs
kubectl logs -l app.kubernetes.io/name=argocd-server
```

**External Secrets Not Working**:
```bash
# Check External Secrets Operator
kubectl get pods -l app.kubernetes.io/name=external-secrets

# Check ExternalSecret resources
kubectl get externalsecrets -A
kubectl describe externalsecret <secret-name>
```

**Longhorn Storage Issues**:
```bash
# Check Longhorn status
kubectl get pods -l app.kubernetes.io/name=longhorn

# Check PVC status
kubectl get pvc -A
kubectl describe pvc <pvc-name>
```

### Manual Sync
```bash
# Force sync specific application
kubectl patch application <app-name> -p '{"operation":{"sync":{"syncPolicy":{"syncOptions":["CreateNamespace=true"]}}}}'

# Sync all applications
kubectl get applications -o name | xargs -I {} kubectl patch {} -p '{"operation":{"sync":{}}}'
```
