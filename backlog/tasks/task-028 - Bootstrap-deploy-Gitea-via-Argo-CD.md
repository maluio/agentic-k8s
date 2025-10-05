---
id: task-028
title: Bootstrap deploy Gitea via Argo CD
status: Done
assignee:
  - '@codex'
created_date: '2025-10-05 17:13'
updated_date: '2025-10-05 17:41'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Extend the bootstrap script to register a Gitea Application in Argo CD and ensure the resulting Service exposes a NodePort.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Bootstrap registers a Gitea Application manifest with Argo CD.
- [x] #2 Gitea Service is configured as type NodePort after bootstrap completes.
- [x] #3 Bootstrap output or docs explain how to reach the Gitea NodePort.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add an Argo CD Application manifest that drives the upstream Gitea Helm chart with SQLite storage and a fixed HTTP NodePort.
2. Update bootstrap.sh to apply the Application manifest, ensure the gitea namespace exists, and wait for the deployment to become ready.
3. Surface the chosen NodePort in the bootstrap summary and expand the README with instructions for reaching Gitea.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Added manifests/argocd/gitea-application.yaml targeting the upstream Gitea Helm chart (sqlite, NodePort 32330, admin seeding with `GiteaRocks!123`).
- Extended bootstrap.sh to apply the Application, tolerate rollout hiccups, capture the NodePort, and print it in the summary alongside existing info.
- Documented Gitea access details (NodePort, default credentials) in README.
- Validation: bash -n scripts/bootstrap.sh
<!-- SECTION:NOTES:END -->
