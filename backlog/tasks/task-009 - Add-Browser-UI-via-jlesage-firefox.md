---
id: task-009
title: Add Browser UI via jlesage/firefox
status: Done
assignee:
  - '@codex'
created_date: '2025-10-03 08:46'
updated_date: '2025-10-03 09:28'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Deploy the jlesage/firefox container through a Helm chart and expose a web UI that can reach the services installed by bootstrap (Gitea, Argo CD, Zellij, nginx).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Create a chart that runs the jlesage/firefox image with a web-accessible UI and persists user settings.
- [x] #2 Integrate the chart with bootstrap so the Firefox UI is deployed automatically and configured to reach the cluster services.
- [x] #3 Document how to launch the browser UI and use it to access Gitea, Argo CD, Zellij, and other endpoints.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Scaffold a Helm chart under charts/firefox that runs jlesage/firefox with persistent config and web VNC access.
2. Wire the chart into scripts/bootstrap.sh and expose a port-forward so the browser UI can reach local services.
3. Update README/bootstrap docs to explain how to use the Firefox UI and validate with helm lint + bootstrap run.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Added charts/firefox leveraging jlesage/firefox with persistent config and exposed port 5800 via ClusterIP.
- Bootstrap now deploys Firefox, forwards port 5801, and reports credentials alongside existing services.
- README updated to highlight the in-cluster browser and new port-forward.
<!-- SECTION:NOTES:END -->
