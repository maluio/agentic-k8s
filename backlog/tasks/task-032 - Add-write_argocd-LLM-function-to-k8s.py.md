---
id: task-032
title: Add write_argocd LLM function to k8s.py
status: Done
assignee:
  - '@agent-k'
created_date: '2025-10-09 06:39'
updated_date: '2025-10-09 06:42'
labels:
  - agent
  - llm
  - argocd
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement a write_argocd function in agent/llm_tools/k8s.py that writes ArgoCD application manifests to disk. The function takes an ArgoCD application manifest (YAML content) and writes it to the agent/manifests directory, following the same naming convention where the app name (from metadata.name) corresponds to the YAML filename.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Function signature accepts manifest_content parameter (YAML string)
- [x] #2 Function parses YAML to extract metadata.name for filename
- [x] #3 Function writes YAML file to /workspace/agent/manifests/ directory
- [x] #4 Function follows naming convention: metadata.name = file name (e.g., 'my-app' -> 'my-app.yaml')
- [x] #5 Function handles write errors gracefully
- [x] #6 Function validates that input is valid YAML
- [x] #7 Function returns success message or error description
- [x] #8 Function is properly decorated as an LLM tool
- [x] #9 Function includes clear docstring explaining usage and convention
- [x] #10 Function is added to __all__ exports
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Review existing k8s.py structure and read_argocd function
2. Determine YAML parsing library to use (check if available in container)
3. Implement write_argocd function with YAML parsing and validation
4. Extract metadata.name from parsed YAML
5. Write manifest to /workspace/agent/manifests with proper error handling
6. Add function to __all__ exports
7. Test the function with valid YAML manifest
8. Test error handling with invalid YAML and write errors
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Summary

Implemented `write_argocd` function in agent/llm_tools/k8s.py that writes ArgoCD application manifests to disk after validating YAML and extracting the application name.

## Changes Made

- **Modified**: `Dockerfile`
  - Added PyYAML installation for YAML parsing support

- **Modified**: `agent/llm_tools/k8s.py`
  - Added `import yaml` statement
  - Implemented `write_argocd(manifest_content: str) -> str` function
  - Added function to `__all__` exports

## Implementation Details

**Function Behavior**:
- Accepts ArgoCD application manifest as YAML string
- Validates YAML syntax using yaml.safe_load()
- Extracts metadata.name field to determine filename
- Sanitizes filename to prevent path traversal attacks
- Writes to /workspace/agent/manifests/{app-name}.yaml
- Returns success message or descriptive error

**Validation Steps**:
1. Parse YAML with yaml.safe_load() - catches syntax errors
2. Verify result is a dictionary/object
3. Check for metadata field existence and type
4. Check for metadata.name field existence and type
5. Validate metadata.name is non-empty string
6. Sanitize filename (reject path separators like / \ ..)

**Security**:
- Uses yaml.safe_load() to prevent code execution
- Sanitizes filenames to prevent directory traversal
- Validates all required fields before writing
- Returns errors as strings (no exceptions)

**Error Handling**:
- YAML parsing errors returned with exception details
- Missing/invalid metadata fields return specific error messages
- Unsafe filenames rejected with clear explanation
- File write errors caught and returned

## Testing

Verified the implementation:

- ✓ Successfully writes valid ArgoCD manifest to disk
- ✓ Extracts correct filename from metadata.name
- ✓ Rejects invalid YAML with parse error
- ✓ Rejects manifests missing metadata.name
- ✓ File created with correct content
- ✓ Function properly exported in `__all__`
- ✓ Comprehensive docstring with examples
- ✓ PyYAML 6.0.3 installed in container
<!-- SECTION:NOTES:END -->
