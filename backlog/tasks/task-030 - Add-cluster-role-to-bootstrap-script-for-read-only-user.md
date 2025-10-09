---
id: task-030
title: Add cluster role to bootstrap script for read-only user
status: Done
assignee:
  - '@agent-k'
created_date: '2025-10-09 06:01'
updated_date: '2025-10-09 06:04'
labels:
  - bootstrap
  - rbac
  - security
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Grant access to all resources including CRDs to the read-only user in the bootstrap script
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Cluster role grants read access to all standard Kubernetes resources
- [x] #2 Cluster role grants read access to all CRDs
- [x] #3 Cluster role binding associates the role with the read-only user
- [x] #4 Changes are added to the bootstrap script
- [x] #5 Bootstrap script successfully applies the cluster role configuration
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Analyze current RBAC setup in ensure_agent_kubeconfig function
2. Research Kubernetes ClusterRole configuration for read-all access including CRDs
3. Create a custom ClusterRole with comprehensive read permissions
4. Update ensure_agent_kubeconfig to create custom ClusterRole and ClusterRoleBinding
5. Test the bootstrap script to ensure it applies correctly
6. Verify the read-only user has access to all resources including CRDs
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Summary

Replaced the built-in `view` ClusterRole with a custom `agent-readonly-all` ClusterRole that grants comprehensive read-only access to all Kubernetes resources including CRDs.

## Changes Made

- **Modified**: `cluster/scripts/bootstrap.sh:98-136`
  - Replaced `clusterrole=view` with custom `agent-readonly-all` ClusterRole
  - Updated ClusterRoleBinding name to `agent-readonly-all-binding`
  - Added inline ClusterRole definition using kubectl apply with heredoc

## ClusterRole Permissions

The new ClusterRole grants read-only access via three rules:

1. **All API resources**: `apiGroups: ["*"]`, `resources: ["*"]`, `verbs: ["get", "list", "watch"]`
   - Covers all standard Kubernetes resources (pods, deployments, services, etc.)
   - Includes all CRDs from any API group

2. **Resource statuses**: `apiGroups: ["*"]`, `resources: ["*/status"]`, `verbs: ["get", "list", "watch"]`
   - Allows reading status subresources for all resources

3. **Non-resource URLs**: `nonResourceURLs: ["*"]`, `verbs: ["get"]`
   - Grants access to endpoints like /healthz, /metrics, etc.

## Testing

Verified the implementation:

- ✓ Bash syntax validation passed
- ✓ YAML syntax validation passed (kubectl dry-run)
- ✓ Applied ClusterRole successfully to running cluster
- ✓ Verified read access to standard resources (pods)
- ✓ Verified read access to CRDs (customresourcedefinitions)
- ✓ Verified read access to custom resources (addons.k3s.cattle.io)
- ✓ Verified write operations (create/delete) are correctly denied

## Security Notes

This ClusterRole provides read-only access to ALL cluster resources, which is appropriate for monitoring and observability use cases. The service account cannot modify any resources, ensuring it remains safe for automated agent workflows.
<!-- SECTION:NOTES:END -->
