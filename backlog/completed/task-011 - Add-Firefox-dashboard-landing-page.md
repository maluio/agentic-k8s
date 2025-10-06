---
id: task-011
title: Add Firefox dashboard landing page
status: Done
assignee:
  - '@codex'
created_date: '2025-10-03 11:51'
updated_date: '2025-10-03 12:12'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add a sidecar container to the Firefox Helm deployment that serves a simple static HTML page enumerating the cluster services exposed by bootstrap. Configure the Firefox container to open that landing page by default so users have quick links to each endpoint.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Firefox Helm release runs an additional sidecar that exposes the static dashboard page.
- [x] #2 The dashboard lists URLs for every service the bootstrap script surfaces (Gitea, Argo CD HTTP/gRPC, nginx example, Firefox, etc.).
- [x] #3 Firefox container uses FF_OPEN_URL (or equivalent) so the browser opens the dashboard on launch.
- [x] #4 Repository documentation explains the new landing page and how to extend it.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Update dashboard links to use internal service DNS names accessible from the Firefox pod.
2. Refresh documentation to clarify link targets and note how to customize for external access.
3. Validate templating and close out notes/ACs.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Added an nginx sidecar serving a ConfigMap-backed dashboard page listing bootstrap endpoints.
- Wired FF_OPEN_URL so Firefox opens the dashboard by default and documented customization options.

- Swapped dashboard URLs to use in-cluster service DNS names for compatibility with the remote Firefox session.
- Clarified README guidance about customizing links for internal versus port-forwarded access.

- Added Argo CD credential hint to the dashboard and documentation so users know how to retrieve the current admin password.
<!-- SECTION:NOTES:END -->
