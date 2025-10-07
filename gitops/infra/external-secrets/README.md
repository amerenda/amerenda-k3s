# External Secrets Operator with Bitwarden Integration

This directory contains the configuration for the External Secrets Operator with Bitwarden Secrets Manager integration, allowing you to manage Kubernetes secrets from your Bitwarden account.

## Files

- `values.yaml` - Helm chart values for the External Secrets Operator with Bitwarden SDK Server
- `external-secrets-operator.yaml` - ArgoCD application manifest for the External Secrets Operator
- `bitwarden-secretstore.yaml` - SecretStore configuration for Bitwarden (manually applied)
- `NOTES.txt` - Post-deployment instructions
- `README.md` - This documentation file

## Configuration

The External Secrets Operator is configured with:

- **Namespace**: `external-secrets`
- **Chart Version**: `0.9.11`
- **Repository**: `https://charts.external-secrets.io`
- **Branch**: `feat/external-secrets` (will be moved to `main` when ready)
- **Bitwarden SDK Server**: Enabled for Bitwarden Secrets Manager integration

## Features Enabled

- RBAC enabled
- Service account creation
- Health and readiness probes
- Metrics collection
- Leader election
- Webhook support
- CRD management
- **Bitwarden SDK Server** for Secrets Manager integration
- TLS support for secure communication

## Bitwarden Setup Instructions

### 1. Get Your Bitwarden Access Token

1. Log into your Bitwarden web vault
2. Go to **Settings** → **Security** → **API Keys**
3. Create a new API key with appropriate permissions
4. Save the access token securely

### 2. Create Bitwarden Credentials Secret

1. Base64 encode your Bitwarden access token:
   ```bash
   echo -n "your-bitwarden-access-token" | base64
   ```

2. Copy the template and update it:
   ```bash
   cp bitwarden-credentials-secret.yaml.template bitwarden-credentials-secret.yaml
   ```

3. Edit `bitwarden-credentials-secret.yaml` and replace `<YOUR_BITWARDEN_ACCESS_TOKEN>` with your base64-encoded token

4. Apply the secret:
   ```bash
   kubectl apply -f bitwarden-credentials-secret.yaml
   ```

### 3. Deploy the Configuration

The External Secrets Operator and Bitwarden SDK Server will be automatically deployed by ArgoCD when the application is synced.

### 4. Create Your First ExternalSecret

1. Copy the example:
   ```bash
   cp example-externalsecret.yaml my-secret.yaml
   ```

2. Edit `my-secret.yaml` and update:
   - Replace `my-bitwarden-secret-id` with your actual Bitwarden secret ID
   - Replace `my-property` with the field names from your Bitwarden secret
   - Update the target secret name and namespace

3. Apply the ExternalSecret:
   ```bash
   kubectl apply -f my-secret.yaml
   ```

## Usage Examples

### Basic Secret Retrieval
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: my-app-secret
  namespace: my-app
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: bitwarden-secretstore
    kind: SecretStore
  target:
    name: my-app-credentials
  data:
    - secretKey: username
      remoteRef:
        key: my-bitwarden-secret-id
        property: username
    - secretKey: password
      remoteRef:
        key: my-bitwarden-secret-id
        property: password
```

### Multiple Secrets
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: multi-secret
  namespace: my-app
spec:
  refreshInterval: 30m
  secretStoreRef:
    name: bitwarden-secretstore
    kind: SecretStore
  target:
    name: app-secrets
  data:
    - secretKey: db-password
      remoteRef:
        key: database-secret-id
        property: password
    - secretKey: api-key
      remoteRef:
        key: api-secret-id
        property: key
```

## Troubleshooting

### Check External Secrets Operator Status
```bash
kubectl get pods -n external-secrets
kubectl logs -n external-secrets deployment/external-secrets
```

### Check Bitwarden SDK Server Status
```bash
kubectl get pods -n external-secrets -l app.kubernetes.io/name=bitwarden-sdk-server
kubectl logs -n external-secrets deployment/bitwarden-sdk-server
```

### Check SecretStore Status
```bash
kubectl get secretstore -n external-secrets
kubectl describe secretstore bitwarden-secretstore -n external-secrets
```

### Check ExternalSecret Status
```bash
kubectl get externalsecret -A
kubectl describe externalsecret my-secret -n my-namespace
```

## Moving to Main Branch

When ready to move to the main branch, update the `targetRevision` in the root-app.yaml file from `feat/external-secrets` to `main`.
