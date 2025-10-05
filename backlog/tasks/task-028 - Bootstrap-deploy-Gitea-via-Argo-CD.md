---
id: task-028
title: Bootstrap deploy Gitea via Argo CD
status: Done
assignee:
  - '@codex'
created_date: '2025-10-05 17:13'
updated_date: '2025-10-05 17:23'
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
1. Add an Argo CD Application manifest (e.g., manifests/argocd/gitea.yaml) that references the Bitnami Gitea Helm chart with service.type=NodePort and a fixed HTTP nodePort.
2. Update bootstrap.sh to apply the Application manifest, ensure the gitea namespace exists, and wait for the deployment to become ready.
3. Surface the chosen NodePort in the bootstrap summary and expand the README with instructions for reaching Gitea.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Added manifests/argocd/gitea-application.yaml referencing the Bitnami Gitea chart with NodePort HTTP exposure at 32330.
- Extended bootstrap.sh to apply the Application, wait for the workload, capture the NodePort, and print it in the summary alongside existing info.
- Documented Gitea access details (NodePort, default credentials) in README.
- Validation: bash -n scripts/bootstrap.sh

- Updated Gitea Application chart version to 3.2.22 after Bitnami repo removed 12.0.0.
<!-- SECTION:NOTES:END -->
