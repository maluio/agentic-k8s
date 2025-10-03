---
id: task-012
title: Remove extraneous port-forwards
status: Done
assignee:
  - '@codex'
created_date: '2025-10-03 12:14'
updated_date: '2025-10-03 12:25'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Restrict bootstrap port-forwarding to only the Firefox service. Eliminate the remaining localhost port-forwards (Gitea, Argo CD, nginx, etc.) so users rely on in-cluster DNS or other access patterns instead.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Bootstrap script no longer starts port-forwards other than Firefox.
- [x] #2 Documentation reflects the reduced port-forward list.
- [x] #3 Any automation or helper scripts referencing removed port-forwards are updated or pruned.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Review bootstrap script and supporting docs for current port-forward usage.
2. Remove non-Firefox port-forwards from bootstrap and adjust any dependent helpers.
3. Update documentation to reflect Firefox as the sole default port-forward and capture notes/tests.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Removed long-lived kubectl port-forwards for Gitea, Argo CD, and the nginx example; bootstrap now only leaves the Firefox tunnel running.
- Reworked Gitea seeding to use in-cluster CLI operations and bundle streaming instead of localhost HTTP access, keeping functionality without exposing extra ports.
- Updated README guidance so users rely on the Firefox landing page for service URLs and documented that only the Firefox port-forward is started.

- Validated shell changes with bash -n scripts/bootstrap.sh.
<!-- SECTION:NOTES:END -->
