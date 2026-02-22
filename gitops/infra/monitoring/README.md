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
| Grafana | `http://grafana.amer.home` (10.100.20.205) |
| Prometheus | ClusterIP only (internal) |
