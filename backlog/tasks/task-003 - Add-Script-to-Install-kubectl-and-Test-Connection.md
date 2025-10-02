---
id: task-003
title: Add Script to Install kubectl and Test Connection
status: Done
assignee:
  - '@codex'
created_date: '2025-10-02 13:20'
updated_date: '2025-10-02 13:45'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Provide an automated way to install kubectl and confirm it can reach the local Kubernetes cluster provisioned for the project.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Add a script at scripts/install-kubectl.sh that installs kubectl at the project-supported version and leaves the binary on PATH.
- [x] #2 Script verifies connectivity to the local cluster by running a kubectl command (e.g., version or get nodes) and surfaces errors when access fails.
- [x] #3 Document how to run the script and any environment variables or prerequisites needed for successful execution.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Select kubectl distribution, pin desired version, and verify prerequisites across supported OS targets.
2. Implement scripts/install-kubectl.sh with idempotent install logic, PATH placement, and a cluster connectivity check.
3. Update project docs with script usage, configuration options, and troubleshooting guidance.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Added scripts/install-kubectl.sh to download a pinned kubectl release, install it, and validate cluster access with kubectl get nodes.
- Documented usage, prerequisites, and configuration overrides in README.md.
- Validated script syntax via bash -n.

- Adjusted kubectl client verification to use --output=json to stay compatible with newer kubectl releases.
<!-- SECTION:NOTES:END -->
