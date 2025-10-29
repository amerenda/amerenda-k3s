# ARC Runners

This directory contains the configuration for the GitHub Actions Runner Scale Set.

## Purpose

The runner scale set deploys ephemeral runners that scale based on workflow demand.

## Files

- `values.yaml` - Helm values for the runner scale set

## Configuration

- **Namespace**: `arc-systems`
- **Sync Wave**: 5 (installs after controller and external-secrets)
- **Runner Labels**: `self-hosted`, `linux`, `arc-runner-set`
- **Scaling**: 0-10 runners based on demand

## Dependencies

- ARC Controller (must be installed first)
- GitHub App credentials (via ExternalSecret)
