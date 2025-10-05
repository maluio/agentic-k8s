---
id: task-020
title: Expose GitOps repo from agent pod
status: Done
assignee:
  - '@codex'
created_date: '2025-10-04 15:00'
updated_date: '2025-10-04 15:06'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Enable the agent workspace to push chart changes into a Git repository that Argo CD watches so updates deploy automatically.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Publish a Git repository accessible from the agent pod for committing chart changes.
- [x] #2 Configure Argo CD to watch that repository for its Applications.
- [x] #3 Document how to push updates from the agent pod and trigger the automated rollout.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Extend bootstrap to seed a dedicated charts repository and wire Argo CD credentials to it.
2. Point the Argo CD applications at the new repo so chart pushes trigger reconciles.
3. Document the GitOps workflow and verify manifests (helm lint).
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Bootstrap now seeds an agentic-k8s-charts Git repository and ensures Argo CD credentials for both repos.
- Argo CD Applications reference the charts repo so pushes from the agent pod reconcile automatically.
- Documented the GitOps workflow and validated with helm lint charts/agent.
<!-- SECTION:NOTES:END -->
