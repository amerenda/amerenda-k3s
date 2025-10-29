# ARC Controller

This directory contains the configuration for the GitHub Actions Runner Controller (ARC) controller component.

## Purpose

The ARC controller manages runner scale sets cluster-wide and handles authentication with GitHub.

## Files

- `values.yaml` - Helm values for the ARC controller
- `externalsecret.yaml` - ExternalSecret for GitHub App credentials (creates `controller-manager` secret used by both controller and runners)

## Configuration

- **Namespace**: `arc-systems`
- **Sync Wave**: 1 (installs early, must be synced before ARC runners)
- **GitHub Auth**: Uses GitHub App authentication via ExternalSecret
- **Secret Name**: `controller-manager` (used by both ARC controller and runner scale sets)

## Sync Order

This application must be synced and healthy before the ARC runners application can be synced. ArgoCD sync waves (wave 1 for controller, wave 5 for runners) ensure this ordering automatically.

## Dependencies

- External Secrets Operator (for GitHub App credentials)
- Bitwarden SecretStore (for credential management)
