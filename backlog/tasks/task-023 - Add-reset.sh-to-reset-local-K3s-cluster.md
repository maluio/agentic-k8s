---
id: task-023
title: Add reset.sh to reset local K3s cluster
status: Done
assignee:
  - '@codex'
created_date: '2025-10-05 09:53'
updated_date: '2025-10-05 10:19'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Provide a helper script that tears down the local K3s environment so users can start fresh without manually typing the sequence of commands.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Script stops workloads with sudo /usr/local/bin/k3s-killall.sh.
- [x] #2 Script uninstalls K3s via sudo /usr/local/bin/k3s-uninstall.sh.
- [x] #3 Script optionally removes the local kubeconfig copy ~./.kube/config 2>/dev/null.
- [x] #4 Document the new reset workflow in README.
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Added scripts/reset.sh to stop workloads, uninstall K3s, and remove the local kubeconfig copy (uses sudo automatically when needed).
- Documented the reset workflow in README under a new "Reset the Cluster" section.
- Verified the script parses with bash -n.
<!-- SECTION:NOTES:END -->
