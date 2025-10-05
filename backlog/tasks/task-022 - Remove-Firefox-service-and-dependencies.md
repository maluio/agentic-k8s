---
id: task-022
title: Remove Firefox service and dependencies
status: Done
assignee:
  - '@codex'
created_date: '2025-10-05 09:40'
updated_date: '2025-10-05 09:44'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Retire the in-cluster Firefox browser experience, including its Helm chart, bootstrap integration, and documentation references.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Delete the Firefox Helm chart and any manifests or scripts that deploy it.
- [x] #2 Update bootstrap to skip Firefox-specific setup and ensure the flow still completes successfully.
- [x] #3 Purge documentation, dashboards, and summaries that reference Firefox or its access instructions.
- [x] #4 Verify bootstrap and lint/test tooling pass after the Firefox removal.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Audit scripts, docs, and charts to catalog Firefox references.
2. Remove Firefox Helm chart and bootstrap integration so no deployment artifacts remain.
3. Clean documentation and summaries to reflect environment without Firefox.
4. Run lint/tests to confirm toolchain still passes post-removal.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Removed the Firefox Helm chart and stripped bootstrap logic that installed or reported it.
- Refreshed README guidance to focus on in-cluster service access and dropped Firefox-specific instructions.
- Ran helm lint on charts/agent, charts/nginx-example, and charts/argo-cd to confirm remaining charts pass.
<!-- SECTION:NOTES:END -->
