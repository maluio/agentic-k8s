---
id: task-026
title: Bootstrap agent kubeconfig setup
status: Done
assignee:
  - '@codex'
created_date: '2025-10-05 16:29'
updated_date: '2025-10-05 16:43'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Extend the bootstrap script so it creates an agent subdirectory and writes a kubeconfig file configured with read-only credentials to the cluster.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Bootstrap script creates an agent/ subdirectory when it runs.
- [x] #2 Script saves a kubeconfig file inside agent/ with the expected name.
- [x] #3 Kubeconfig grants read-only access to the Kubernetes cluster (no mutating permissions).
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Review bootstrap script to locate where to inject agent kubeconfig setup.
2. Ensure a dedicated read-only service account and binding exist via kubectl apply logic.
3. Create the agent/ directory and write a kubeconfig sourcing cluster server/CA and service account token.
4. Surface the location in bootstrap output and adjust docs if helpful.
5. Validate the script with shellcheck/bash -n as appropriate.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Added ensure_agent_kubeconfig() to bootstrap.sh to provision a view-bound service account and render agent/kubeconfig.
- Updated bootstrap summary output and README with the new read-only context.
- Validation: bash -n scripts/bootstrap.sh

- Hardened ensure_agent_kubeconfig to reuse existing kubeconfig so reruns stay idempotent.

- Fixed kubeconfig generation to use raw CA data (or base64-encoded file) so kubectl trusts the cluster.

- Regenerate the kubeconfig on each bootstrap to refresh expiring tokens while keeping operations idempotent.
<!-- SECTION:NOTES:END -->
