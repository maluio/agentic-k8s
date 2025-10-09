---
id: task-034
title: Add k8s-agent-root ArgoCD application to bootstrap script
status: Done
assignee:
  - '@agent-k'
created_date: '2025-10-09 07:09'
updated_date: '2025-10-09 07:12'
labels:
  - bootstrap
  - argocd
  - gitops
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Configure the bootstrap script to create an ArgoCD application named 'k8s-agent-root' that installs manifests from the GitHub repository path agent/manifests. This application should use manual sync policy, the default project, and be deployed to the argocd namespace.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 ArgoCD application named 'k8s-agent-root' is created
- [x] #2 Source repoURL points to https://github.com/maluio/agentic-k8s
- [x] #3 Source path is set to agent/manifests
- [x] #4 Source targetRevision is set to main branch
- [x] #5 Sync policy is manual (not automated)
- [x] #6 Project is set to default
- [x] #7 Destination namespace is argocd
- [x] #8 Application is created in bootstrap.sh script
- [x] #9 Application manifest is applied using kubectl
- [x] #10 Bootstrap script waits for application to be created successfully
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Review current bootstrap.sh script structure
2. Determine the best location to add ArgoCD application creation
3. Create ArgoCD application manifest for k8s-agent-root
4. Add function to bootstrap.sh to apply the application
5. Ensure application is applied after ArgoCD is installed
6. Test the bootstrap script changes
7. Verify application is created and shows in ArgoCD
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Summary

Added `create_agent_root_application` function to bootstrap.sh that creates the k8s-agent-root ArgoCD application for managing manifests from the GitHub repository.

## Changes Made

- **Modified**: `cluster/scripts/bootstrap.sh`
  - Added `create_agent_root_application()` function after `install_argocd()`
  - Updated `main()` to call the new function
  - Function creates ArgoCD application using kubectl apply with heredoc

## Implementation Details

**ArgoCD Application Spec**:
- name: k8s-agent-root
- namespace: argocd
- project: default
- repoURL: https://github.com/maluio/agentic-k8s
- targetRevision: main
- path: agent/manifests
- destination.server: https://kubernetes.default.svc
- destination.namespace: argocd
- syncPolicy: {} (manual sync, no automation)

**Function Behavior**:
1. Logs "Creating k8s-agent-root ArgoCD application"
2. Applies application manifest using kubectl with heredoc
3. Waits up to 30 seconds for application to be created
4. Adds summary message on success
5. Logs warning if creation times out

**Integration**:
- Function is called in main() after install_argocd()
- This ensures ArgoCD is fully installed before creating the application
- Called before ensure_agent_kubeconfig() and ensure_argocd_nodeport()

## Testing

Verified the implementation:

- ✓ Bash syntax validation passed
- ✓ Application manifest YAML is valid (kubectl dry-run)
- ✓ Application creates successfully in cluster
- ✓ Application shows correct repoURL, path, and targetRevision
- ✓ Sync policy is manual (empty syncPolicy)
- ✓ Project is default
- ✓ Destination namespace is argocd
- ✓ Application status shows "OutOfSync, Healthy" (expected for manual sync)
- ✓ Wait logic works correctly

## Manual Sync Policy

The application uses manual sync policy (empty syncPolicy object) which means:
- ArgoCD detects changes but does not auto-sync
- User/admin must manually trigger sync via ArgoCD UI or CLI
- This provides control over when manifest changes are applied to the cluster
<!-- SECTION:NOTES:END -->
