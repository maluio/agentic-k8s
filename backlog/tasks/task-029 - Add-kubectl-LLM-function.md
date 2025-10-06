---
id: task-029
title: Add kubectl LLM function
status: Done
assignee:
  - '@codex'
created_date: '2025-10-06 07:40'
updated_date: '2025-10-06 07:51'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Expose a custom tool for the llm CLI (via --function) that wraps kubectl commands.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Implement a Python function compatible with llm's tool interface that shells out to kubectl.
- [x] #2 Register the function so llm CLI can invoke it via --function.
- [x] #3 Document the available function and usage example in project docs.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add a Python module (e.g. tools/kubectl_llm.py) defining the kubectl() function with docstring and subprocess handling compatible with llm --functions.
2. Provide helper __init__/package metadata if needed and ensure function is importable via file path.
3. Document usage in README (or AGENTS.md) including safety notes and example llm command.
4. Validate with linting/basic execution snippet (e.g. python -m compileall or simple test) and update task notes.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Added tools/kubectl_llm.py exposing kubectl() for llm --functions with argument parsing, namespace/context support, and safe error handling.
- Documented usage example and safety guidance in README.
- Validation: python3 -m compileall tools/kubectl_llm.py; python3 -c "import tools.kubectl_llm as kl; print(kl.kubectl('version --client'))"
<!-- SECTION:NOTES:END -->
