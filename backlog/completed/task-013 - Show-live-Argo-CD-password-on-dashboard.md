---
id: task-013
title: Show live Argo CD password on dashboard
status: Done
assignee:
  - '@codex'
created_date: '2025-10-03 13:05'
updated_date: '2025-10-03 13:41'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Expose the current Argo CD admin password on the Firefox landing page so users can sign in without running kubectl manually. Fetch the secret during bootstrap/chart templating and inject the value into the rendered dashboard HTML.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Bootstrap captures the current Argo CD admin password and passes it to the Firefox release.
- [x] #2 Dashboard displays the Argo CD admin password alongside the login instructions.
- [x] #3 Documentation calls out that the password is surfaced automatically and how to rotate it.
- [x] #4 Security implications are considered and documented (e.g., limited to local lab environment).
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Trace how the Firefox chart is configured today to accept custom values and identify a mechanism for injecting the Argo CD admin password from bootstrap.
2. Update bootstrap + values to surface the password in a ConfigMap or secret consumed by the dashboard and render it alongside the Argo CD link.
3. Document security considerations and rotation guidance, then add implementation notes and close the task.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- bootstrap now reads the Argo CD admin secret and, when available, passes it to the Firefox Helm release via --set-string.
- Dashboard ConfigMap renders the password in a dedicated credentials panel with rotation guidance.
- README and chart docs explain that the password appears automatically and note the lab-only security posture.

- Added copy-to-clipboard button and visual feedback to the password panel to avoid whitespace being copied from the dashboard.
<!-- SECTION:NOTES:END -->
