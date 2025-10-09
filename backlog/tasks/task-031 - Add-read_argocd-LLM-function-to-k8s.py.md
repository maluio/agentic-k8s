---
id: task-031
title: Add read_argocd LLM function to k8s.py
status: Done
assignee:
  - '@agent-k'
created_date: '2025-10-09 06:19'
updated_date: '2025-10-09 06:21'
labels:
  - agent
  - llm
  - argocd
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement a read_argocd function in agent/llm_tools/k8s.py that reads ArgoCD application manifests from disk. The function takes an ArgoCD application name and returns the corresponding YAML file contents from agent/manifests directory, using the convention that the app name matches the YAML filename.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Function signature accepts argocd_app_name parameter
- [x] #2 Function reads YAML file from agent/manifests/ directory
- [x] #3 Function follows naming convention: app name = file name (e.g., 'my-app' -> 'my-app.yaml')
- [x] #4 Function returns the file contents as string
- [x] #5 Function handles file not found errors gracefully
- [x] #6 Function is properly decorated as an LLM tool
- [x] #7 Function includes clear docstring explaining usage and convention
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Review existing k8s.py structure and function patterns
2. Determine the correct path resolution for agent/manifests directory
3. Implement read_argocd function with proper error handling
4. Add function to __all__ exports
5. Test the function with existing nginx-example.yml file
6. Test error handling with non-existent file
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Summary

Implemented `read_argocd` function in agent/llm_tools/k8s.py that reads ArgoCD application manifests from the agent/manifests directory.

## Changes Made

- **Modified**: `agent/llm_tools/k8s.py`
  - Added `from pathlib import Path` import
  - Implemented `read_argocd(argocd_app_name: str) -> str` function
  - Added function to `__all__` exports

## Implementation Details

**Function Behavior**:
- Accepts ArgoCD application name as parameter
- Resolves path to agent/manifests directory relative to the k8s.py file
- Tries both `.yaml` and `.yml` extensions (in that order)
- Returns file contents as string on success
- Returns descriptive error message if file not found or unreadable

**Path Resolution**:
- Uses `Path(__file__).parent.parent / "manifests"` to locate manifests directory
- This ensures the function works regardless of where it's called from

**Error Handling**:
- OSError exceptions are caught and returned as error messages
- File not found returns helpful message showing what was searched for

**Naming Convention**:
- App name "nginx-example" → looks for "nginx-example.yaml" or "nginx-example.yml"
- Follows standard ArgoCD naming where metadata.name matches filename

## Testing

Verified the implementation:

- ✓ Successfully reads existing nginx-example.yml file
- ✓ Returns correct YAML content
- ✓ Handles non-existent files gracefully with error message
- ✓ Function properly exported in `__all__`
- ✓ Function signature and type hints correct
- ✓ Comprehensive docstring with examples included
- ✓ Supports both .yaml and .yml extensions
<!-- SECTION:NOTES:END -->
