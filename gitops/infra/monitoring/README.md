# Monitoring Stack

Cluster monitoring via [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) (v82.1.0).

## Components

- **Prometheus** -- metrics collection and storage (7-day retention, 10Gi Longhorn PVC)
- **Grafana** -- dashboards and visualization at `http://grafana.amer.home`
- **node-exporter** -- host-level metrics (CPU, memory, disk, network) per node
- **kube-state-metrics** -- Kubernetes object metrics (pods, deployments, nodes)
- **Prometheus Operator** -- manages Prometheus and ServiceMonitor CRDs

AlertManager is disabled.

## Access

| Service | Address |
|---------|---------|
| Grafana | `https://grafana.amer.home` (via Traefik Ingress, TLS) |
| Prometheus | ClusterIP only (internal) |

### Grafana login

- **Username:** `admin`
- **Password:** If you previously reset it via the CLI, use that password. Otherwise decode from the cluster secret:
  ```bash
  kubectl get secret infra-monitoring-grafana -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d
  ```
  (No trailing newline; copy the output as the password.)

`root_url` and `domain` are set so that browser login at `https://grafana.amer.home` works (cookies and redirects). After changing values, sync/restart Grafana so the new config is applied.

If login still fails, Grafana only applies the secret password when it first creates the admin user. If the secret was changed after the initial deploy (e.g. by Helm), the running instance may still use the original password. Reset it via the Grafana CLI in the pod:
  ```bash
  kubectl exec -n monitoring deploy/infra-monitoring-grafana -- grafana cli admin reset-admin-password NEW_PASSWORD
  ```
  Then log in with `admin` and the new password.
