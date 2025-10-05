---
id: task-021
title: Replace kubectl port-forward with NodePort services
status: Done
assignee:
  - '@codex'
created_date: '2025-10-05 08:30'
updated_date: '2025-10-05 08:36'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Phase out direct kubectl port-forward usage by switching to NodePort-based access. Ensure service definitions and workflows are updated accordingly.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Search codebase and docs to confirm no kubectl port-forward commands remain.
- [x] #2 Expose previously forwarded components via NodePort services with appropriate security configuration.
- [x] #3 Update documentation and scripts to reflect NodePort access workflow.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inventory all kubectl port-forward usage across scripts, docs, and manifests.
2. Update Kubernetes manifests or Helm charts to expose necessary components via NodePort with sane port assignments and security.
3. Adjust automation and local workflows to target NodePort endpoints instead of port-forward.
4. Smoke test access paths via NodePort and document the workflow changes.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Replaced Firefox port-forward with a NodePort service and surfaced the address in bootstrap summary.
- Updated project docs and Helm NOTES to remove kubectl port-forward instructions in favor of NodePort guidance.
- Ran helm lint charts/firefox and charts/nginx-example to validate chart updates.
<!-- SECTION:NOTES:END -->
