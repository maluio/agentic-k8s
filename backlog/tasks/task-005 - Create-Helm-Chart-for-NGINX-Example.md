---
id: task-005
title: Create Helm Chart for NGINX Example
status: To Do
assignee: []
created_date: '2025-10-02 13:24'
updated_date: '2025-10-02 13:26'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Package an example NGINX deployment as a Helm chart and ensure the chart can be installed on the local cluster provisioned by the project scripts.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Add a Helm chart under charts/nginx-example that deploys an NGINX Deployment with a Service exposing HTTP traffic.
- [ ] #2 Provide default values and README guidance so the chart can be installed without additional configuration.
- [ ] #3 Demonstrate installation by including a scripted or documented helm install command and a verification step that confirms the release is running.
<!-- AC:END -->
