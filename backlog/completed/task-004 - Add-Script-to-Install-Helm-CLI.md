---
id: task-004
title: Add Script to Install Helm CLI
status: Done
assignee:
  - '@codex'
created_date: '2025-10-02 13:20'
updated_date: '2025-10-02 13:47'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Automate installation of the Helm command-line tool so developers can package and deploy charts on the local Kubernetes environment.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Provide a script at scripts/install-helm.sh that installs Helm at the pinned project version and leaves the binary accessible on PATH.
- [x] #2 Include validation in the script that confirms helm version output matches the expected release.
- [x] #3 Document how to run the script and any prerequisites so new developers can install Helm without additional guidance.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Choose the Helm release and supported OS/architecture matrix, verifying prerequisites for local dev hosts.
2. Implement scripts/install-helm.sh with idempotent download/install logic and a version validation step.
3. Document installation usage, configuration overrides, and troubleshooting so developers can bootstrap Helm reliably.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Added scripts/install-helm.sh to download a pinned Helm release, install it, and validate the version.
- Documented prerequisites, install command, and configuration overrides in README.md.
- Verified script syntax via bash -n.
<!-- SECTION:NOTES:END -->
