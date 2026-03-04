# CLAUDE.md — AI Assistant Guide for amerenda-k3s

This file provides context for AI assistants (Claude, Cursor, etc.) working in this repository. Read it before making changes.

---

## What This Repository Is

A GitOps-managed, production home lab Kubernetes cluster running on Raspberry Pi hardware. The cluster hosts:
- **Home Assistant** (smart home automation)
- **Pi-hole** (network-wide DNS filtering)
- **UniFi Network Application** (network management)
- **Tailscale** (secure mesh VPN)

Infrastructure is fully declarative: everything from cluster provisioning (Ansible) to application deployment (ArgoCD) lives in Git.

---

## Repository Structure

```
amerenda-k3s/
├── ansible/                    # Cluster provisioning and node setup
│   ├── inventory/inventory.ini # Node definitions (controllers + agents)
│   ├── group_vars/             # Per-group Ansible variables
│   ├── playbooks/
│   │   ├── infrastructure/     # RPi setup, k3s install, Longhorn
│   │   └── applications/       # Post-install tasks
│   └── all.yml                 # Master playbook (runs everything)
│
├── bootstrap/                  # One-time cluster bootstrap files
│   ├── appprojects.yaml        # ArgoCD AppProject definitions (infra + application)
│   └── bitwarden-credentials-secret.yaml  # Bitwarden token secret (NEVER commit real tokens)
│
├── gitops/                     # ArgoCD-managed GitOps manifests
│   ├── root-app.yaml           # App-of-Apps root (defines all applications)
│   ├── infra/                  # Infrastructure components
│   │   ├── flannel/            # CNI (wave 0)
│   │   ├── metallb/            # Load balancer (wave 0)
│   │   ├── cert-manager/       # TLS certificates (wave 0)
│   │   ├── traefik/            # Ingress controller (wave 1)
│   │   ├── reloader/           # ConfigMap/Secret watcher (wave 1)
│   │   ├── arc-controller/     # GitHub Actions Runner Controller (wave 1)
│   │   ├── external-secrets/   # Bitwarden secret sync (wave 2)
│   │   ├── longhorn/           # Distributed block storage (wave 3)
│   │   ├── dns/                # BIND9 DNS server (wave 4)
│   │   ├── external-dns/       # Dynamic DNS updates (wave 4)
│   │   ├── tailscale/          # VPN subnet router (wave 5)
│   │   ├── arc-runners/        # GitHub Actions runners (wave 5)
│   │   ├── monitoring/         # Prometheus + Grafana stack (wave 6)
│   │   └── cert-manager-external/ # ClusterIssuers, certificates (wave 20)
│   └── apps/                   # Application deployments
│       ├── home-assistant/     # Smart home (wave 5)
│       ├── pihole/             # DNS filtering (wave 5)
│       └── unifi-network-application/  # Network management (wave 5)
│
├── .github/README.md           # GitHub Actions workflow documentation
├── .HA_VERSION                 # Pins Home Assistant version for CI (currently 2024.10.0)
├── .yamllint.yaml              # YAML linting rules (120 char lines, 2-space indent)
└── summary.md                  # Home Assistant lighting system design document
```

---

## Cluster Hardware

| Host | Role | IP |
|------|------|----|
| rpi5-0 | k3s controller | 10.100.20.10 |
| rpi5-1 | k3s controller | 10.100.20.11 |
| rpi4-0 | k3s controller | 10.100.20.12 |
| rpi3-0 | k3s agent | 10.100.20.13 |

- SSH user: `alex`, key: `~/.ssh/alex_id_ed25519`
- 3-controller HA setup with embedded etcd

---

## ArgoCD Deployment Order (Sync Waves)

Applications are deployed sequentially via ArgoCD sync waves. **Never assign a wave number lower than a dependency.**

| Wave | Components |
|------|-----------|
| 0 | Flannel CNI, MetalLB, cert-manager |
| 1 | Traefik, Reloader, ARC Controller |
| 2 | External Secrets Operator (needs cert-manager for Bitwarden TLS) |
| 3 | Longhorn (needs External Secrets for GCS credentials) |
| 4 | BIND9 DNS, External DNS (need TSIG secrets) |
| 5 | Home Assistant, Pi-hole, UniFi, Tailscale, ARC Runners |
| 6 | Monitoring (Prometheus + Grafana) |
| 20 | cert-manager ClusterIssuers, Certificates |

Wave numbers are set via annotation:
```yaml
annotations:
  argocd.argoproj.io/sync-wave: "5"
```

---

## Adding a New Application

1. Create a directory under `gitops/apps/<app-name>/` or `gitops/infra/<component>/`
2. Add Kubernetes manifests (Deployment, Service, Namespace, etc.)
3. If using Helm, add a `values.yaml` and reference the chart in `root-app.yaml`
4. Add a new `Application` resource to `gitops/root-app.yaml`:
   - Use `project: application` for user-facing apps
   - Use `project: infra` for infrastructure components
   - Set the correct `sync-wave` based on dependencies
5. For secrets: add an `ExternalSecret` referencing the Bitwarden `ClusterSecretStore`
6. Commit and push — ArgoCD auto-syncs

---

## Secrets Management

**All secrets use Bitwarden via External Secrets Operator.** Never hardcode secrets in manifests.

Pattern for creating an ExternalSecret:
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: my-app-secret
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: bitwarden-secretstore
    kind: ClusterSecretStore
  target:
    name: my-app-secret
  data:
    - secretKey: password
      remoteRef:
        key: <bitwarden-secret-id>
```

**Files that MUST NOT be committed:**
- `*.secret`, `*.key`, `*.token`
- `*.kubeconfig`, `ansible/k3s-kubeconfig.yaml`
- `bootstrap/bitwarden-credentials-secret.yaml` with real tokens

---

## Home Assistant Configuration

Home Assistant runs as a single replica in the `home-assistant` namespace backed by a Longhorn PVC. Configuration is managed entirely through Kubernetes ConfigMaps.

### Source → ConfigMap Pipeline

Edit source files in `configuration/`, run the generator, commit the generated ConfigMaps:

```
configuration/automations/*.yaml        →  automations-configmap.yaml
configuration/blueprints/automation/    →  blueprints-configmap.yaml
configuration/scripts/*.yaml            →  scripts-configmap.yaml
configuration/dashboards/*.yaml         →  dashboards-configmap.yaml
configuration/groups.yaml               →  groups-configmap.yaml
configuration/helpers/generated/        →  helpers-input-*-configmap.yaml
```

### Generating ConfigMaps

```bash
cd gitops/apps/home-assistant/configuration/
./generate-configmaps.sh
```

For helpers (requires `jinja2-cli`):
```bash
pip install jinja2-cli
cd gitops/apps/home-assistant/configuration/helpers/
bash generate_helpers.sh
```

**Rooms**: `bedroom`, `bathroom`, `living_room`, `kitchen`, `hallway`

### CI Automation (GitHub Actions)

Two workflows run on the self-hosted `arc-runner-set` runner:

- **`ha-config-check.yaml`**: YAML linting + `hass --script check_config` validation on PRs
- **`ha-generate-configmaps.yaml`**: Auto-regenerates and commits ConfigMaps on push to `main`

The HA version used for CI is pinned in `.HA_VERSION` (currently `2024.10.0`).

### Lighting Automation Architecture

Home Assistant uses a modular blueprint system for lighting:

- `room_switch_control.yaml` — Hue dimmer switch (4-button) per room
- `room_motion_control.yaml` — Motion-triggered lighting per room
- `room_timer_control.yaml` — Time-window-triggered lighting per room

Each room uses per-room input helpers for schedules, brightness, and scene overrides. See `summary.md` for the full design document.

---

## YAML Conventions

All YAML files in this repo must conform to `.yamllint.yaml`:

- **Indentation**: 2 spaces (no tabs)
- **Line length**: 120 characters max (warning only)
- **Truthy values**: `true`/`false`, `yes`/`no`, `on`/`off` are all allowed
- **Document start** (`---`): Optional, not required
- Validate locally: `yamllint gitops/apps/home-assistant/`

For Kubernetes manifests, start with `---` for multi-document files.

---

## GitOps Workflow

All cluster changes go through Git — **never use `kubectl apply` directly for persistent changes.**

```bash
# Make changes to manifests
git add gitops/...
git commit -m "feat: describe what changed and why"
git push

# ArgoCD detects changes and syncs automatically (prune: true, selfHeal: true)
```

To check sync status:
```bash
kubectl get applications -A
kubectl describe application <app-name> -n default
```

Force a sync if needed:
```bash
kubectl patch application <app-name> -n default \
  -p '{"operation":{"sync":{}}}' --type merge
```

---

## Cluster Access

```bash
# All ArgoCD applications
kubectl get applications -A

# Access ArgoCD UI
kubectl port-forward svc/argocd-server 8080:80 -n default
# → http://localhost:8080

# Internal DNS names (via BIND9 + External DNS)
# http://argocd.amer.home
# http://longhorn.amer.home
# http://pihole.amer.home
# http://homeassistant.amer.home
# http://grafana.amer.home
```

---

## Ansible Cluster Management

```bash
# Full cluster setup (first time)
export K3S_TOKEN=$(openssl rand -hex 32)
ansible-playbook -i ansible/inventory/inventory.ini ansible/all.yml

# Specific components only
ansible-playbook -i ansible/inventory/inventory.ini \
  ansible/playbooks/infrastructure/setup-rpi.yml
ansible-playbook -i ansible/inventory/inventory.ini \
  ansible/playbooks/infrastructure/k3s-controller.yml

# Filter by tag
ansible-playbook -i ansible/inventory/inventory.ini \
  ansible/all.yml --tags network
ansible-playbook -i ansible/inventory/inventory.ini \
  ansible/all.yml --tags k3s
ansible-playbook -i ansible/inventory/inventory.ini \
  ansible/all.yml --tags longhorn
```

### Bootstrap (after first install)

```bash
# Apply ArgoCD AppProjects (required before apps can sync)
kubectl apply -f bootstrap/appprojects.yaml

# Apply Bitwarden credentials (manually — fill in token first)
vim bootstrap/bitwarden-credentials-secret.yaml
kubectl apply -f bootstrap/bitwarden-credentials-secret.yaml
```

---

## Monitoring

The monitoring stack (wave 6) includes:
- **Prometheus** — metrics collection
- **Grafana** — dashboards at `https://grafana.amer.home`
- **AlertManager** — alerting

Pre-built dashboards for every component are in `gitops/infra/monitoring/dashboards/`. They follow the naming convention `<scope>-<component>.yaml` (e.g., `infra-longhorn.yaml`, `app-home-assistant.yaml`).

---

## Troubleshooting Cheatsheet

### Longhorn pods crashing
```bash
# Cause: open-iscsi not installed on node
sudo apt update && sudo apt install -y open-iscsi
kubectl delete pod <failing-pod>
```

### Pods stuck in ContainerCreating
```bash
# Cause: Flannel CNI not running
kubectl get pods -n kube-system -l app=flannel
kubectl get application infra-flannel -n default
```

### External Secrets not syncing
```bash
kubectl get clustersecretstore bitwarden-secretstore
kubectl get externalsecrets -A
kubectl describe externalsecret <name>
# Ensure bitwarden-credentials secret exists in default namespace
kubectl get secret bitwarden-credentials -n default
```

### ArgoCD application not syncing
```bash
kubectl get application <name> -n default
kubectl describe application <name> -n default
kubectl logs -l app.kubernetes.io/name=argocd-server -n default
```

### HA ConfigMaps not updating
```bash
# Reloader watches ConfigMaps and restarts pods automatically
kubectl get pods -l app.kubernetes.io/name=reloader
# Check if ConfigMap was regenerated and committed
git log --oneline gitops/apps/home-assistant/*-configmap.yaml
```

---

## Key Design Decisions

- **Single HA replica**: Home Assistant is not cluster-aware; running multiple replicas causes config corruption
- **Reloader**: Stakater Reloader (`infra-reloader`) automatically restarts pods when their ConfigMaps or Secrets change — this is how HA config updates are applied without manual restarts
- **App-of-Apps pattern**: `gitops/root-app.yaml` is the single entry point; ArgoCD manages all child applications from there
- **Helm via ArgoCD multi-source**: Helm charts are referenced by chart repo URL + version in `root-app.yaml`; values files live in this repo under `gitops/infra/<component>/values.yaml`
- **No `kubectl` in CI**: ConfigMap generation scripts use only shell tools (`cat`, `sed`) to avoid requiring cluster access in CI
- **Bitwarden as single secrets backend**: All secrets (GCS, Tailscale, DNS TSIG, Pi-hole, etc.) flow through Bitwarden → External Secrets → Kubernetes Secrets

---

## CI/CD Self-Hosted Runners

GitHub Actions runners run inside the k3s cluster via GitHub Actions Runner Controller (ARC):

- **Label**: `arc-runner-set`
- **Namespace**: `arc-runners`
- **Scale**: 0–10 runners (ephemeral, scale to zero when idle)
- **Auth**: GitHub App (not a PAT)

Runner logs: `kubectl get pods -n arc-runners`
