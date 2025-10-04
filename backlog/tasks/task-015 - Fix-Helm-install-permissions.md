---
id: task-015
title: Fix Helm install permissions
status: To Do
assignee:
  - ''
created_date: '2025-10-04 05:11'
updated_date: '2025-10-04 06:18'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Running scripts/bootstrap.sh fails when scripts/install-helm.sh tries to install into /usr/local/bin without elevated permissions. Update the installer to handle systems where the install directory is not writable by the current user.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 scripts/install-helm.sh succeeds when /usr/local/bin requires sudo
- [ ] #2 bootstrap.sh completes the Helm installation step without manual intervention
- [ ] #3 Documented or logged the path used for Helm so users know where it is installed
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Review scripts/install-helm.sh to understand current install logic
2. Adjust the script to use sudo when installing to protected directories or fallback to a user-writable path
3. Re-run bootstrap helm step to confirm Helm installs successfully and logs installed location
<!-- SECTION:PLAN:END -->
