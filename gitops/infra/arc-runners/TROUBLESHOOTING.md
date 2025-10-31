# ARC Runners Troubleshooting

## 404 Error When Creating Registration Token

If you see an error like:
```
failed to create registration token: POST https://api.github.com/orgs/amerenda/actions/runners/registration-token: 404 Not Found
```

### Cause
**Important:** Personal GitHub accounts cannot use organization-level runners. If you see a 404 with `/orgs/`, you must use repository-level runners instead.

If using an organization, the GitHub App may not have sufficient permissions to create organization-level registration tokens.

### Solution

According to the [GitHub REST API documentation](https://docs.github.com/en/rest/actions/self-hosted-runners?apiVersion=2022-11-28), the endpoint `POST /orgs/{org}/actions/runners/registration-token` requires admin access to the organization.

1. **Go to your GitHub App settings**: https://github.com/organizations/amerenda/settings/apps
2. **Select your app** (e.g., `k3s-arc-runners`)
3. **Navigate to "Permissions & events"**
4. **Under "Organization permissions"**, ensure you have:
   - ✅ **Self-hosted runners**: Read and write (REQUIRED - minimum)
   - ✅ **Organization administration**: Read-only (may be required - try if 404 persists)

5. **Save the changes**
6. **CRITICAL: Reinstall the app** - Go to "Install App" → Click "Configure" next to your organization → Click "Save"
   - This regenerates the installation token with new permissions
7. **Refresh ExternalSecret** (one of these methods):
   - Wait for automatic refresh (default: 1 hour)
   - Or manually refresh: `kubectl delete externalsecret controller-manager -n arc-systems` and let ArgoCD recreate it
   - Or force refresh: `kubectl patch externalsecret controller-manager -n arc-systems --type merge -p '{"spec":{"refreshInterval":"1m"}}'` then revert

### Verify Permissions and Token Refresh

After updating permissions and reinstalling, verify:
```bash
# Check ExternalSecret status
kubectl get externalsecret controller-manager -n arc-systems

# Check secret exists and has data
kubectl get secret controller-manager -n arc-systems

# Check ExternalSecret sync status - should show "SecretSynced"
kubectl describe externalsecret controller-manager -n arc-systems
```

**Important Notes:**
- ✅ You DO need to reinstall the GitHub App after changing permissions (this generates a new installation token)
- ✅ The ExternalSecret will automatically refresh, but you can force it by deleting and recreating
- ✅ The GitHub App credentials (App ID, Installation ID, Private Key) in Bitwarden do NOT need to change - only the installation token changes

### Personal GitHub Accounts

**Personal GitHub accounts must use repository-level runners**, not organization-level. The configuration should be:

```yaml
spec:
  repository: amerenda/amerenda-k3s  # Required for personal accounts
```

Repository-level runners require:
- Repository permissions: Actions: Read and write, Administration: Read and write
- Organization permissions: Self-hosted runners: Read and write (for organization accounts only - not needed for personal accounts)

### Organization-Level Runners

Organization-level runners (`organization: amerenda`) only work if:
- You have an actual GitHub organization named "amerenda" (not a personal account)
- The GitHub App has:
  - Organization permissions: Self-hosted runners: Read and write
  - Organization permissions: Organization administration: Read-only (may be required)

