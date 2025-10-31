# ARC Runners Troubleshooting

## 404 Error When Creating Registration Token

If you see an error like:
```
failed to create registration token: POST https://api.github.com/orgs/amerenda/actions/runners/registration-token: 404 Not Found
```

### Cause
The GitHub App doesn't have sufficient permissions to create organization-level registration tokens.

### Solution

1. **Go to your GitHub App settings**: https://github.com/organizations/amerenda/settings/apps
2. **Select your app** (e.g., `k3s-arc-runners`)
3. **Navigate to "Permissions & events"**
4. **Under "Organization permissions"**, ensure you have:
   - ✅ **Self-hosted runners**: Read and write
   - ✅ **Organization administration**: Read-only (REQUIRED for org-level tokens)
5. **Save the changes**
6. **The app will need to be reinstalled** - Go to "Install App" → Click "Configure" → "Save"

### Verify Permissions

After updating permissions and reinstalling, verify the secret is updated:
```bash
kubectl get secret controller-manager -n arc-systems
kubectl get externalsecret controller-manager -n arc-systems
```

### Alternative: Use Repository-Level Runners

If you don't want to grant "Organization administration" permission, you can use repository-level runners instead:

```yaml
spec:
  repository: amerenda/amerenda-k3s  # Instead of organization: amerenda
```

Repository-level runners require:
- Repository permissions: Actions: Read and write, Administration: Read and write
- Organization permissions: Self-hosted runners: Read and write (no admin needed)

