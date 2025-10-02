---
id: task-003
title: Add Script to Install kubectl and Test Connection
status: To Do
assignee: []
created_date: '2025-10-02 13:20'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Provide an automated way to install kubectl and confirm it can reach the local Kubernetes cluster provisioned for the project.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Add a script at scripts/install-kubectl.sh that installs kubectl at the project-supported version and leaves the binary on PATH.
- [ ] #2 Script verifies connectivity to the local cluster by running a kubectl command (e.g., version or get nodes) and surfaces errors when access fails.
- [ ] #3 Document how to run the script and any environment variables or prerequisites needed for successful execution.
<!-- AC:END -->
