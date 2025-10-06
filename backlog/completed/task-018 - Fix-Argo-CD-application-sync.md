---
id: task-018
title: Fix Argo CD application sync
status: Done
assignee:
  - '@codex'
created_date: '2025-10-04 06:00'
updated_date: '2025-10-04 08:03'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
During bootstrap the wait_for_application step warns that the gitea and nginx-example Argo CD applications never reach Synced/Healthy. Investigate why these applications remain out of sync and update the bootstrap workflow or application manifests so they converge.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 bootstrap.sh reports Argo CD applications gitea and nginx-example as Synced/Healthy
- [x] #2 Underlying sync issue is resolved or documented with automatic retry
- [x] #3 A fresh bootstrap run completes without Argo CD application warnings
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect Argo CD application definitions under argocd/ to understand desired state for gitea and nginx-example
2. Use kubectl/argocd commands to determine why applications remain OutOfSync or unhealthy
3. Update manifests or bootstrap sequencing so both applications reach Synced/Healthy on a fresh bootstrap
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Updated scripts/bootstrap.sh to push a real bare repository into Gitea using kubectl exec -i and tar streaming.
- Added ignoreDifferences for the gitea PVC so Argo CD avoids drift on provisioned storage fields.
- Verified scripts/bootstrap.sh now finishes with both gitea and nginx-example applications Synced/Healthy.
<!-- SECTION:NOTES:END -->
