# GitOps Repository Structure

This repository contains the GitOps configuration for your home k3s cluster using ArgoCD.

## Repository Structure

```
gitops/
├── apps/
│   ├── root-app.yaml          # ArgoCD App-of-Apps root application
│   ├── pihole/               # Pi-hole DNS server
│   ├── home-assistant/       # Home Assistant
│   └── tailscale/           # Tailscale VPN
├── infra/                     # Infrastructure applications
│   ├── longhorn/             # Longhorn storage configuration
│   ├── external-secrets/     # External Secrets Operator
│   ├── monitoring/           # Monitoring stack (Prometheus, Grafana, etc.)
│   └── dns/                  # BIND9 DNS server
└── README.md                # This file
```

## How App-of-Apps Works

The `root-app.yaml` contains multiple ArgoCD Application objects that define:

1. **Root Application**: Manages the `apps/` directory
2. **Infrastructure Apps**: Core cluster services (Longhorn, External Secrets, Monitoring)
3. **Application Apps**: User-facing applications (Pi-hole, Home Assistant, Tailscale)

Each application is configured with:
- **Automated Sync**: `prune: true, selfHeal: true`
- **Namespace Creation**: Automatic namespace creation
- **Retry Logic**: Automatic retry on failures
- **Prune Propagation**: Safe resource cleanup

## Directory Guidelines

### `infra/` - Infrastructure Applications
- **Longhorn**: Distributed storage configuration
- **External Secrets**: Secret management
- **Monitoring**: Prometheus, Grafana, AlertManager
- **DNS**: BIND9 DNS server for internal domains
- **Ingress**: NGINX, Traefik, or other ingress controllers
- **Cert Manager**: SSL certificate management

### `apps/` - Application Services
- **Pi-hole**: DNS server and ad blocker
- **Home Assistant**: Smart home automation
- **Tailscale**: VPN and secure networking
- **Jellyfin**: Media server (future)
- **Nextcloud**: File sharing and collaboration (future)
- **Bitwarden**: Password manager (future)

## DNS Configuration

After deploying ArgoCD, configure your DNS to point to the LoadBalancer IP:

```bash
# Get the LoadBalancer IP
kubectl get svc -n argocd argocd-server

# Add DNS entry
# argocd.amer.local -> <LOADBALANCER_IP>
```

## Security Considerations

- **Tailscale Integration**: Consider protecting ArgoCD behind Tailscale
- **Ingress Controller**: Use NGINX or Traefik for HTTPS termination
- **RBAC**: Configure proper role-based access control
- **Secrets**: Use External Secrets Operator for sensitive data

## Adding New Applications

1. Create manifest files in appropriate directory (`infra/` or `services/`)
2. Add new Application object to `root-app.yaml`
3. Commit and push to trigger ArgoCD sync
4. Monitor application status in ArgoCD UI

## Troubleshooting

- **Sync Issues**: Check ArgoCD logs and application events
- **Resource Conflicts**: Ensure namespaces don't conflict
- **Network Issues**: Verify LoadBalancer IP and DNS resolution
- **Permission Issues**: Check RBAC and service account permissions
