---
id: task-016
title: Create argocd namespace before repo secret
status: Done
assignee:
  - '@codex'
created_date: '2025-10-04 05:13'
updated_date: '2025-10-04 07:16'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
scripts/bootstrap.sh currently attempts to create the Argo CD repository secret before the argocd namespace exists, causing the bootstrap to abort. Ensure the namespace is created or the secret is applied after the namespace is available.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 bootstrap.sh no longer fails when ensuring the Argo CD repository secret
- [x] #2 argocd namespace is present before the secret apply
- [x] #3 bootstrap flow continues past the Gitea setup step on a fresh run
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Review bootstrap.sh around ensure_repo_secret for namespace ordering
2. Ensure argocd namespace exists before creating the repository secret (create namespace or reorder logic)
3. Re-run bootstrap to confirm the secret step and subsequent stages succeed
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Simulated fresh environment by uninstalling argocd/gitea and deleting namespaces before rerunning scripts/bootstrap.sh.
- ensure_repo_secret now creates the argocd namespace before applying the repository secret; bootstrap completed without hitting prior failure.
- Verified repo-agentic-k8s secret present in argocd namespace after run.
<!-- SECTION:NOTES:END -->
