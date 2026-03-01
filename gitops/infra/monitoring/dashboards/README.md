# Grafana dashboards (Infra & Apps)

ConfigMaps in this directory are applied to the `monitoring` namespace and picked up by the Grafana dashboard sidecar (label `grafana_dashboard: "1"`). They appear in Grafana under folders **Infra** and **Apps**.

- **Infra:** one dashboard per infrastructure Argo app (Flannel, Longhorn, Traefik, cert-manager, etc.).
- **Apps:** one dashboard per application (Pi-hole, Home Assistant, UniFi Network Application).

Each dashboard is a minimal placeholder (title + overview panel). Edit the JSON or add panels in Grafana and re-export if you want to persist changes back here.
