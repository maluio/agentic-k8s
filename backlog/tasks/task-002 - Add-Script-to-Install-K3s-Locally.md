---
id: task-002
title: Add Script to Install K3s Locally
status: Done
assignee:
  - '@codex'
created_date: '2025-10-02 13:20'
updated_date: '2025-10-02 13:32'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Automate provisioning of a local K3s cluster so developers can bootstrap Kubernetes in a single step.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Create a script at scripts/install-k3s.sh that installs or upgrades K3s on the supported development OS and can be re-run safely.
- [x] #2 Ensure the script starts the K3s service and writes kubeconfig details or export instructions for kubectl access.
- [x] #3 Document script usage and prerequisites in the repository so a new developer can run it without additional guidance.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Confirm target developer OS support and gather K3s installation prerequisites.
2. Implement scripts/install-k3s.sh with idempotent install logic, service management, and kubeconfig export guidance.
3. Validate the script end-to-end, capture teardown steps, and document usage/prerequisites in project docs.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Added scripts/install-k3s.sh to install or upgrade K3s, restart the service, and copy kubeconfig for the invoking user.
- Documented prerequisites, usage, verification, and cleanup steps in README.md.
- Validated the script syntax with bash -n.
<!-- SECTION:NOTES:END -->
