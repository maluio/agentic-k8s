---
id: task-025
title: Remove Helm usage and install Argo CD via manifests
status: Done
assignee:
  - '@codex'
created_date: '2025-10-05 13:24'
updated_date: '2025-10-05 13:30'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Simplify bootstrap by dropping Helm entirely; install Argo CD directly with kubectl and remove any Helm-based deployment logic or dependencies.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Stop installing or requiring the Helm binary anywhere in the scripts.
- [x] #2 Deploy Argo CD using kubectl create namespace argocd and kubectl apply with the upstream install manifest.
- [x] #3 Remove chart management and Helm release handling from bootstrap and related docs.
- [x] #4 Verify bootstrap still provisions the environment successfully without Helm.
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Removed Helm from the toolchain: deleted charts/, argocd/ manifests, and the install-helm.sh helper while rewriting bootstrap to avoid Helm entirely.
- Bootstrap now provisions only K3s and installs Argo CD via kubectl apply against the upstream manifest, reporting port-forward guidance once components are ready.
- Updated README to describe the leaner workflow and verified the script with bash -n.
<!-- SECTION:NOTES:END -->
