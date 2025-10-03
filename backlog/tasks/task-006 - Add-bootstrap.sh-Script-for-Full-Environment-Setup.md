---
id: task-006
title: Add bootstrap.sh Script for Full Environment Setup
status: Done
assignee:
  - '@codex'
created_date: '2025-10-03 05:51'
updated_date: '2025-10-03 06:07'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Provide a one-stop bootstrap experience that provisions all tooling, Helm charts, Argo CD configuration, and port-forwards required by this repository on a freshly provisioned developer machine.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Introduce scripts/bootstrap.sh that installs prerequisites, runs repo-provided installers (k3s, kubectl, helm), deploys Argo CD + applications, and starts required kubectl port-forwards in an idempotent manner.
- [x] #2 Ensure the script reports which subsystems it installs or skips (already present) and surfaces the generated Argo CD admin credentials in the output.
- [x] #3 Document usage assumptions and how to rerun the script safely in project docs.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Audit existing scripts and deployments to outline bootstrap steps and dependency order.
2. Implement scripts/bootstrap.sh orchestrating prerequisite installs, chart deployments, and port-forward setup with idempotent checks and summary output.
3. Document bootstrap usage, rerun expectations, and credential handling in README; validate script via shellcheck/bash -n.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Added scripts/bootstrap.sh to orchestrate K3s/kubectl/Helm installs, Helm deployments, Argo CD configuration, and standard port-forwards with idempotent checks and final summary output.
- Updated README with bootstrap instructions and aligned port-forward guidance for the nginx example.
- Verified the script via bash -n and execution against an existing environment to ensure reruns skip completed work while refreshing Argo CD configuration.
<!-- SECTION:NOTES:END -->
