---
id: task-015
title: Fix Helm install permissions
status: Done
assignee:
  - '@codex'
created_date: '2025-10-04 05:11'
updated_date: '2025-10-04 06:48'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Running scripts/bootstrap.sh fails when scripts/install-helm.sh tries to install into /usr/local/bin without elevated permissions. Update the installer to handle systems where the install directory is not writable by the current user.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 scripts/install-helm.sh succeeds when /usr/local/bin requires sudo
- [x] #2 bootstrap.sh completes the Helm installation step without manual intervention
- [x] #3 Documented or logged the path used for Helm so users know where it is installed
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Review scripts/install-helm.sh to understand current install logic
2. Adjust the script to use sudo when installing to protected directories or fallback to a user-writable path
3. Re-run bootstrap helm step to confirm Helm installs successfully and logs installed location
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Ran scripts/install-helm.sh with /usr/local/bin lacking write access; installer retried with sudo and succeeded, logging the install path.
- Triggered scripts/bootstrap.sh with helm absent; ensure_helm step completed automatically and bootstrap continued without manual intervention.
- Confirmed helm v3.15.2 available on PATH post-install and cleaned up temporary backups.
<!-- SECTION:NOTES:END -->
