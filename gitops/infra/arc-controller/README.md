# ARC Controller

This directory contains the configuration for the GitHub Actions Runner Controller (ARC) controller component.

## Purpose

The ARC controller manages runner scale sets cluster-wide and handles authentication with GitHub.

## Files

- `values.yaml` - Helm values for the ARC controller
- `externalsecret.yaml` - ExternalSecret to fetch GitHub App credentials from Bitwarden

## Configuration

- **Namespace**: `arc-systems`
- **Sync Wave**: 1 (installs early)
- **GitHub Auth**: Uses GitHub App authentication via ExternalSecret
- **Secret Name**: `github-app-arc-token`

## Dependencies

- External Secrets Operator (for GitHub App credentials)
- Bitwarden SecretStore (for credential management)
