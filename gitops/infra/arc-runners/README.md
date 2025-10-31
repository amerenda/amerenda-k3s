# ARC Runners

This directory contains the configuration for the GitHub Actions Runner Scale Set.

## Purpose

The runner scale set deploys ephemeral runners that scale based on workflow demand.

## Files

- `runnerset.yaml` - RunnerSet CRD resource that defines the runner scale set

## Configuration

- **Namespace**: `arc-systems`
- **Sync Wave**: 5 (installs after controller and external-secrets)
- **Runner Labels**: `self-hosted`, `linux`, `arc-runner-set`
- **Scaling**: 0-10 runners based on demand

## Dependencies

- **ARC Controller** (must be synced and healthy first - see `arc-controller` application)
- GitHub App credentials (via ExternalSecret `controller-manager` from arc-controller)

## Sync Order

This application depends on the ARC controller being synced first. ArgoCD sync waves automatically ensure the controller (wave 1) is synced before runners (wave 5). Do not manually sync this application until the `infra-arc-controller` application is healthy.
