# AGENTS.md — AI Agent Guide for amerenda-k3s

Context and operating instructions for AI agents (Claude Code, etc.) working in this repo.
Read this alongside `CLAUDE.md`, which covers repo structure, hardware, and conventions.

---

## What You Have Access To

### ArgoCD CLI
ArgoCD is installed and authenticated. The `argocd` CLI is your primary tool for interacting
with the cluster. It is already configured at `~/.config/argocd/config`.

```bash
# Credentials are in .env (gitignored). Source it if running scripts:
source .env

# If the auth token has expired (JWT, ~10 day TTL), re-login:
argocd login argocd.amer.home --username admin --plaintext
# then update ARGOCD_AUTH_TOKEN in .env from ~/.config/argocd/config
```

All `argocd` commands need `--plaintext` (HTTP, not HTTPS):
```bash
argocd app list --plaintext
argocd app get <name> --plaintext
argocd app sync <name> --plaintext
argocd app logs <name> --plaintext
argocd app diff <name> --plaintext
```

### No kubectl / No SSH
You do **not** have `kubectl` available on this machine, and SSH keys for the cluster nodes
are not configured here. All cluster interaction goes through the ArgoCD CLI or REST API.

The ArgoCD REST API is accessible at `http://argocd.amer.home/api/v1/` and the auth token
lives in `~/.config/argocd/config`.

### GitHub CLI
`gh` is available and authenticated. All git changes must go through a PR:
```bash
git checkout -b fix/my-change
# make changes
git add <files> && git commit -m "..."
git push origin fix/my-change
gh pr create --title "..." --body "..."
gh pr merge <N> --merge
```
After merging, ArgoCD auto-syncs within ~3 minutes. Force an immediate sync with:
```bash
argocd app sync <app-name> --plaintext
```

---

## Cluster Topology

| Host | Role | IP |
|------|------|----|
| rpi5-0 | k3s controller | 10.100.20.10 |
| rpi5-1 | k3s controller | 10.100.20.11 |
| rpi4-0 | k3s controller | 10.100.20.12 |
| rpi3-0 | k3s agent | 10.100.20.13 |
| murderbot | LAN workstation (docker-compose) | 10.100.20.19 |

- **Traefik VIP** (MetalLB): `10.100.20.203` — all ingress traffic hits this IP
- **Internal DNS**: BIND9 (`amer.home` zone) — only accessible from LAN, not from cluster pods
- **Public DNS**: DigitalOcean (`amer.dev` zone) — managed by `external-dns-do`
- **Cluster DNS**: CoreDNS forwards to `1.1.1.1` and `8.8.8.8` (not internal BIND9)

### Critical networking note
Pods inside the cluster resolve DNS via CoreDNS → `1.1.1.1,8.8.8.8`. Internal `.amer.home`
names do **not** resolve from within the cluster. Always use `.amer.dev` hostnames when
configuring Traefik backends that point to LAN hosts (e.g. `murderbot.amer.dev`, not
`murderbot.amer.home`).

---

## ArgoCD Apps

| App name | Gitops path | What it manages |
|----------|-------------|-----------------|
| `root` | `gitops/` | App-of-apps (discovers all other apps) |
| `infra-argocd-config` | `gitops/infra/argocd-config` | ArgoCD's own `argocd-cm` settings |
| `infra-flannel` | `gitops/infra/flannel` | CNI networking |
| `infra-metallb` | `gitops/infra/metallb` | Load balancer IPs |
| `infra-cert-manager` | Helm chart | TLS certificate operator |
| `infra-cert-manager-external` | `gitops/infra/cert-manager` | ClusterIssuers, Certificates |
| `infra-traefik` | Helm chart + `gitops/infra/traefik/values.yaml` | Ingress controller |
| `infra-external-secrets` | Helm chart + templates | Bitwarden secret sync |
| `infra-longhorn` | Helm chart | Distributed block storage |
| `infra-dns` | `gitops/infra/dns` | BIND9 + DNSEndpoints |
| `infra-external-dns` | Helm chart + values | DNS updates → BIND9 (amer.home) |
| `infra-external-dns-do` | Helm chart + values | DNS updates → DigitalOcean (amer.dev) |
| `infra-ingresses` | `gitops/infra/ingresses` | ArgoCD + Longhorn ingresses |
| `infra-monitoring` | Helm chart + dashboards | Prometheus + Grafana |
| `infra-reloader` | Helm chart | ConfigMap/Secret watcher |
| `infra-tailscale` | `gitops/infra/tailscale` | VPN subnet router |
| `infra-arc-controller` | OCI Helm chart | GitHub Actions runner controller |
| `infra-arc-runners` | OCI Helm chart | GitHub Actions runner scale set |
| `app-moltbook` | `gitops/apps/moltbook` | Moltbook proxy → murderbot:3002 |
| `app-home-assistant` | `gitops/apps/home-assistant` | Smart home |
| `app-pihole` | `gitops/apps/pihole` | DNS filtering |
| `app-unifi-network-application` | `gitops/apps/unifi-network-application` | UniFi controller |

---

## Live Services

All services are exposed via Traefik on `10.100.20.203` with Let's Encrypt TLS.

| URL | Expected response | Notes |
|-----|-------------------|-------|
| `https://moltbook.amer.dev` | 200 | Moltbook control UI (murderbot:3002) |
| `https://argocd.amer.dev` | 200 | ArgoCD UI |
| `https://homeassistant.amer.dev` | 200 | Home Assistant |
| `https://grafana.amer.dev` | 302 | Grafana (redirects to login) |
| `https://pihole.amer.dev` | 403 | Pi-hole (requires auth header) |
| `https://longhorn.amer.dev` | 200 | Longhorn storage dashboard |
| `https://unifi.amer.dev` | 400 | UniFi (HTTPS-only backend quirk) |

Internal (amer.home) services are accessible from the LAN but not relevant for gitops work.

---

## How to Verify Things Are Working

```bash
# Check all ArgoCD apps
argocd app list --plaintext

# Check a specific app's sync status and conditions
argocd app get <app-name> --plaintext

# Check pod logs (only available while app is running)
argocd app logs <app-name> --plaintext

# Check what's out of sync
argocd app diff <app-name> --plaintext

# Test a public HTTPS endpoint
curl -skI https/<host>.amer.dev | head -3

# Check TLS cert issuer
echo | openssl s_client -connect <host>.amer.dev:443 -servername <host>.amer.dev 2>/dev/null \
  | openssl x509 -noout -issuer

# Check DNS propagation
dig +short <hostname> @1.1.1.1
dig +short <hostname> @8.8.8.8
```

---

## Secrets

All secrets are stored in Bitwarden and synced into the cluster via External Secrets Operator.
Never hardcode secrets in manifests. See `CLAUDE.md` for the ExternalSecret pattern.

The only secret you can read from this machine is the ArgoCD auth token in
`~/.config/argocd/config`.

---

## Gotchas Learned the Hard Way

**ArgoCD excludes `Endpoints` and `EndpointSlice` by default (v3+)**
Override in `argocd-cm` via `gitops/infra/argocd-config/argocd-cm.yaml`. Our config
keeps `Endpoints` excluded (auto-generated noise) but allows `EndpointSlice` management
so static external backends (like moltbook → murderbot) can be gitops-managed.
When creating a manual `EndpointSlice`, include `conditions.ready: true` or Traefik
will treat the endpoint as unhealthy and return 503.

**Traefik blocks ExternalName services by default**
Enable with `providers.kubernetesIngress.allowExternalNameServices: true` in Helm values
(not via `additionalArguments`). See `gitops/infra/traefik/values.yaml`.

**ExternalName services pointing to `.amer.home` names return 502 from pods**
Cluster CoreDNS forwards to `1.1.1.1,8.8.8.8`. Internal BIND9 is not reachable from pods.
Use `.amer.dev` names or a ClusterIP + EndpointSlice with a hardcoded IP instead.

**8.8.8.8 has a 30-minute negative DNS cache (SOA min TTL = 1800s)**
If a record didn't exist in DO DNS and 8.8.8.8 cached a NXDOMAIN, it won't resolve
for up to 30 minutes even after the A record is added. This causes ~50% failure rate
since CoreDNS randomly picks between 1.1.1.1 and 8.8.8.8.

**Traefik PVC + Longhorn deadlocks rolling updates**
With `replicaCount: 1` and a Longhorn `ReadWriteOnce` PVC, the new pod can't mount the
PVC while the old pod holds it. Solution: disable `persistence` entirely (cert-manager
handles TLS, so Traefik's built-in ACME storage is not needed).

**PodDisruptionBudget `minAvailable: 1` blocks pod replacement**
With 1 replica, the PDB prevents the old pod from terminating. Disable PDB or set
`minAvailable: 0` when `replicaCount: 1`.

**cert-manager `selector.dnsNames` blocks wildcard solver matching**
A `selector.dnsNames` on a ClusterIssuer solver can prevent cert-manager from matching
the correct solver for certain domains. Remove the selector to make it a catch-all.

**external-dns CRD source must be explicitly listed**
`DNSEndpoint` CRDs are only watched when `crd` is in the `sources` list in values.yaml.
It is not included by default.

**`external-dns-do` TXT owner prefix conflicts**
Two external-dns instances managing the same zone need different `txtOwnerId` and
`txtPrefix` values. The amer.home instance uses defaults; the amer.dev instance uses
`txtOwnerId: external-dns-do` and `txtPrefix: do-`.

**ArgoCD sync wave ordering**
external-dns-do is at wave 21 (after cert-manager-external at 20) because it needs the
`do-dns-api-key` Secret which is managed by External Secrets / cert-manager-external wave.
