---
id: task-008
title: Add Helm Chart for Zellij Access
status: Done
assignee:
  - '@codex'
created_date: '2025-10-03 07:15'
updated_date: '2025-10-03 07:33'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Provide a Helm chart that deploys a Zellij instance accessible via Kubernetes Service so users can connect to a shared terminal environment.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Create a chart under charts/zellij that deploys Zellij in the cluster and exposes a Kubernetes Service for client connections.
- [x] #2 Integrate the new chart into the bootstrap workflow so the service is installed automatically.
- [x] #3 Update the bootstrap summary to display connection details or credentials required for accessing Zellij.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Scaffold a lightweight Helm chart under charts/zellij that runs a Zellij server with an exposed Kubernetes Service.
2. Hook the chart into scripts/bootstrap.sh and update the summary output to surface connection details/credentials.
3. Document the addition in README and verify bootstrap/helm lint coverage.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Added charts/zellij with init container + ttyd front-end downloading the Zellij binary and exposing it via ClusterIP service.
- Wired zellij deployment into scripts/bootstrap.sh, starting a 5555 port-forward and surfacing the URL in the summary.
- Updated README to list Zellij among bootstrap deliverables and highlight the web endpoint.
<!-- SECTION:NOTES:END -->
