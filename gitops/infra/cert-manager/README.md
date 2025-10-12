# cert-manager Infrastructure

This directory contains the Helm chart configuration for cert-manager v1.19.0.

## Overview

cert-manager is a Kubernetes add-on to automate the management and issuance of TLS certificates from various issuing sources. It will ensure certificates are valid and up to date, and attempt to renew certificates at an appropriate time before expiry.

## Configuration

The configuration is defined in `values.yaml` and includes:

- **CRD Installation**: Automatically installs cert-manager CRDs
- **Security**: Runs with non-root user and proper security contexts
- **Resources**: Configured with appropriate CPU and memory limits
- **Monitoring**: Prometheus metrics and health checks enabled
- **RBAC**: Proper role-based access control configured

## Key Features

- Automatic TLS certificate management
- Support for Let's Encrypt and other ACME providers
- Integration with various DNS providers
- Prometheus metrics and monitoring
- Webhook validation for certificate requests

## Usage

This application is managed by ArgoCD and will be automatically deployed to the `cert-manager` namespace.

## Dependencies

- Kubernetes cluster with RBAC enabled
- Helm 3.x
- ArgoCD for GitOps deployment

## Certificate Issuers

After deployment, you can create ClusterIssuer or Issuer resources to configure certificate authorities like Let's Encrypt.

Example ClusterIssuer for Let's Encrypt:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: alex@amer.dev
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```

## Monitoring

cert-manager exposes metrics on port 9402 at the `/metrics` endpoint for Prometheus monitoring.
