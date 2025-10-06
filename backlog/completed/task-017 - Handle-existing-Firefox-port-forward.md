---
id: task-017
title: Handle existing Firefox port-forward
status: Done
assignee:
  - '@codex'
created_date: '2025-10-04 05:36'
updated_date: '2025-10-04 06:26'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
scripts/bootstrap.sh emits a warning because the Firefox port-forward fails with 'address already in use' even when an existing kubectl port-forward is already listening on 127.0.0.1:5801. Improve ensure_port_forward to detect an already active listener and avoid retrying or to handle the in-use port gracefully.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 bootstrap.sh recognizes an existing Firefox port-forward and does not warn
- [x] #2 Bootstrap run leaves exactly one kubectl port-forward for Firefox active
- [x] #3 Failure to bind 127.0.0.1:5801 results in clear guidance if no port-forward is running
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect ensure_port_forward logic to understand the existing process detection
2. Update the function to check for an existing port-forward listener before attempting to start a new one and improve warning messaging
3. Verify bootstrap.sh handles repeated runs without spurious warnings and leaves a single Firefox port-forward active
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Added detection for existing kubectl or socket listeners before starting Firefox port-forward.
- Added explicit log detail when port 5801 already bound by a non-kubectl process.
- Validated scenarios: (1) new port-forward started when none exist, (2) existing port-forward detected without warnings, (3) conflicting process surfaces detailed warning.
<!-- SECTION:NOTES:END -->
