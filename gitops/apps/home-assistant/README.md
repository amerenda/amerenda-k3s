# Home Assistant (GitOps-managed)

- Single replica (Home Assistant is not cluster-aware; avoids config corruption)
- Config PVC: homeassistant-config (Longhorn, RWX)
- Deployed via ArgoCD app `app-home-assistant` defined in `gitops/root-app.yaml`
- Follow `GITOPS-RULES.md`: commit changes; no secrets in git

To change image/resources or replicas, edit `home-assistant.yaml` and push.
