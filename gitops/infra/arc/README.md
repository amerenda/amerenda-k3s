# GitHub Actions Runner Controller (ARC) Setup

This directory contains the GitOps configuration for deploying GitHub Actions Runner Controller (ARC) on your k3s cluster.

## Prerequisites

Before deploying ARC, you need to set up a GitHub App for authentication.

### 1. Create GitHub App

1. Go to [GitHub App Settings](https://github.com/organizations/amerenda/settings/apps/new)
2. Fill in the following details:
   - **GitHub App name**: `k3s-arc-runners` (or your preference)
   - **Homepage URL**: `https://github.com/amerenda`
   - **Webhook**: Uncheck "Active" (not needed for self-hosted runners)
   
3. **Repository permissions**:
   - Actions: Read and write
   - Administration: Read and write (for self-hosted runners)
   - Metadata: Read-only (automatically selected)
   
4. **Organization permissions**:
   - Self-hosted runners: Read and write
   
5. **Where can this GitHub App be installed?**: Only on this account
6. Click "Create GitHub App"

### 2. Generate Private Key

1. After creation, scroll to "Private keys" section
2. Click "Generate a private key"
3. Download the `.pem` file (you'll need this content)

### 3. Install the App

1. Go to "Install App" in the left sidebar
2. Click "Install" next to your organization
3. Select "All repositories" to allow org-wide access
4. Note the **App ID** (shown on the app settings page)
5. Note the **Installation ID** (shown in URL after installation: `/settings/installations/INSTALLATION_ID`)

### 4. Store Credentials in Bitwarden

Create three separate secrets in Bitwarden:

1. **`github-app-arc-id`**
   - Secret Key: `github_app_id`
   - Value: Your App ID (e.g., `123456`)

2. **`github-app-arc-installation-id`**
   - Secret Key: `github_app_installation_id`
   - Value: Your Installation ID (e.g., `789012`)

3. **`github-app-arc-private-key`**
   - Secret Key: `github_app_private_key`
   - Value: Full content of the `.pem` file (including `-----BEGIN RSA PRIVATE KEY-----` and `-----END RSA PRIVATE KEY-----` lines)

## Deployment

The ARC infrastructure is deployed via ArgoCD with the following components:

### ARC Controller (`infra-arc-controller`)
- **Sync Wave**: 1 (installs early)
- **Namespace**: `arc-systems`
- **Purpose**: Manages runner scale sets cluster-wide

### Runner Scale Set (`infra-arc-runners`)
- **Sync Wave**: 5 (installs after controller and external-secrets)
- **Namespace**: `arc-systems`
- **Purpose**: Deploys ephemeral runners that scale based on workflow demand

## Configuration

### Controller Configuration (`values.yaml`)
- Resource limits and requests
- Security context settings
- RBAC configuration
- Webhook settings

### Runner Scale Set Configuration (`runner-scale-set-values.yaml`)
- GitHub configuration (uses ExternalSecret for credentials)
- Runner labels: `self-hosted`, `linux`, `arc-runner-set`
- Scaling configuration (0-10 runners)
- Resource limits and security context

## Usage

Once deployed, GitHub Actions workflows can use the self-hosted runners by specifying:

```yaml
runs-on: arc-runner-set
```

The runners will automatically scale up when jobs are queued and scale down when idle.

## Monitoring

You can monitor the ARC controller and runners using:

```bash
# Check controller status
kubectl get pods -n arc-systems

# Check runner scale set
kubectl get runnerscaleset -n arc-systems

# Check individual runners
kubectl get pods -n arc-systems -l app.kubernetes.io/name=gha-runner-scale-set
```

## Troubleshooting

### Common Issues

1. **Runners not starting**: Check ExternalSecret is populated with correct GitHub App credentials
2. **Authentication failures**: Verify GitHub App permissions and installation
3. **Scaling issues**: Check resource limits and node capacity

### Logs

```bash
# Controller logs
kubectl logs -n arc-systems -l app.kubernetes.io/name=gha-runner-scale-set-controller

# Runner logs
kubectl logs -n arc-systems -l app.kubernetes.io/name=gha-runner-scale-set
```

## Security Notes

- GitHub App authentication is more secure than Personal Access Tokens
- Runners run with restricted security context
- Credentials are managed via External Secrets Operator
- Runners are ephemeral and don't persist state between jobs
