---
id: task-024
title: Expose installed services via NodePort
status: Done
assignee:
  - '@codex'
created_date: '2025-10-05 11:58'
updated_date: '2025-10-05 12:03'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Update project-managed services to use NodePort exposure so they are reachable from outside the cluster without manual port-forwards.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Inventory chart/service definitions managed by this repo and switch relevant ClusterIP services to NodePort.
- [x] #2 Ensure NodePort assignments avoid conflicts and are documented.
- [x] #3 Update bootstrap and docs to reflect the new access model.
- [x] #4 Verify deployments and tests still pass after exposure changes.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inventory service definitions across charts/ manifests to identify ClusterIP usage.
2. Select NodePort allocations that avoid conflicts and update charts/manifests accordingly.
3. Refresh bootstrap outputs and README to describe the new access model.
4. Run lint/tests to confirm charts still pass and update task notes.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Switched Gitea, Argo CD, and nginx-example services to NodePort with fixed allocations (30300/30480/31443/30800) and updated Helm manifests accordingly.
- Bootstrap summary now reports node IP + NodePort URLs and README documents the external access matrix.
- Validated charts with helm lint (gitea, argo-cd, nginx-example) and reran bash -n on bootstrap script.
<!-- SECTION:NOTES:END -->
