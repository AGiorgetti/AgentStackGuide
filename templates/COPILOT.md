# COPILOT.md

Repository instructions for GitHub Copilot Chat.

## Required Contract

Follow `AGENT_EXECUTION_CONTRACT.md` exactly.

## Task Assignment Inputs

Human must provide per run:
- Assigned branch name
- Assigned worktree path
- Task scope
- Validation commands

## Mandatory Behavior

1. Confirm branch/worktree before edits.
2. Keep changes strictly in scope.
3. Never rebase another agent branch.
4. Never force-push shared branches.
5. Commit only in assigned branch/worktree.
6. Stop and report when blocked by cross-branch conflicts.

## Response Format

```text
Summary:
- ...

Files Changed:
- ...

Validation:
- <command>: PASS/FAIL

Risks:
- ...

TODO:
- ...
```
