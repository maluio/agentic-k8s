---
id: task-019
title: Add agent app for Git operations
status: Done
assignee:
  - '@codex'
created_date: '2025-10-04 08:30'
updated_date: '2025-10-04 08:34'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Provision an "agent" workload that runs continuously so we can exec into it for Git workflows against the in-cluster Gitea instance.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Deploy an "agent" application that loops continuously to stay running.
- [x] #2 Ensure the container image has git installed and configured to reach the Gitea service so pull/push works.
- [x] #3 Document how to exec into the pod and authenticate against Gitea for Git operations.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Scaffold a new Helm chart that runs a persistent utility pod with Git configured for Gitea access.
2. Register the chart with Argo CD so the application stays reconciled.
3. Update bootstrap flow and docs to highlight how to use the new agent pod.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Added a dedicated agent Helm chart that deploys an alpine/git pod with credentials bootstrap for the lab Gitea instance.
- Registered the chart under Argo CD and updated bootstrap.sh to wait for the new application.
- Documented how to exec into the pod and use the ready-to-go Git configuration in README.
- Validation: helm lint charts/agent
<!-- SECTION:NOTES:END -->
