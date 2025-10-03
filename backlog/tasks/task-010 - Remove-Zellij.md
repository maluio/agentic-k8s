---
id: task-010
title: Remove Zellij
status: Done
assignee:
  - '@codex'
created_date: '2025-10-03 10:47'
updated_date: '2025-10-03 10:49'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Retire the Zellij terminal multiplexer from the stack now that it is no longer required. Remove installation automation and any remaining references so the environment defaults to the standard tooling.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 All automation or provisioning scripts stop installing or configuring Zellij.
- [x] #2 Repository files and manifests no longer reference Zellij.
- [x] #3 Documentation is updated to reflect that Zellij is not part of the toolset.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Search the repository for Zellij usage across scripts, Helm charts, and manifests.
2. Remove Zellij packages and configuration from automation while keeping other tooling unaffected.
3. Update documentation to drop Zellij references and describe the default terminal setup.
4. Run validation (lint/tests) to confirm no residual references remain.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Removed the Zellij Helm chart and automation hooks from bootstrap.
- Refreshed README so the documented tooling and port-forwards match the updated stack.
<!-- SECTION:NOTES:END -->
