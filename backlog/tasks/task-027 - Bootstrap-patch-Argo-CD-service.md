---
id: task-027
title: Bootstrap patch Argo CD service
status: Done
assignee:
  - '@codex'
created_date: '2025-10-05 16:31'
updated_date: '2025-10-05 17:00'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Update the bootstrap script so it patches the Argo CD server Service to use type NodePort.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Bootstrap script applies a patch to the Argo CD server Service.
- [x] #2 Service type is set to NodePort after the script runs.
- [x] #3 Documented NodePort value or discovery step so users know how to access Argo CD.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add a bootstrap helper that patches argocd-server service to type NodePort with a fixed HTTPS NodePort (e.g., 32443) after manifests apply.
2. Update bootstrap summary to print the NodePort and basic access guidance alongside the kubeconfig details.
3. Refresh README access instructions to describe NodePort usage and how to confirm the assigned port.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Added ensure_argocd_nodeport() to force the argocd-server Service onto NodePort 32443 (with fallback) and surface the assigned port in the bootstrap summary.
- Updated summary output and README access instructions to highlight direct HTTPS access and discovery commands for the NodePort.
- Validation: bash -n scripts/bootstrap.sh
<!-- SECTION:NOTES:END -->
