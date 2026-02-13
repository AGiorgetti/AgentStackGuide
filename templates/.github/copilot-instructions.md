# GitHub Copilot Instructions

These instructions apply to Copilot Chat sessions in this repository.

## Branch and Worktree Guardrails

1. Never rebase another agent branch.
2. Never force-push shared branches.
3. Commit only in your assigned branch and worktree.
4. If branch/worktree does not match assignment, stop and report.

## Required Pre-Edit Checks

Run and confirm:
- `git branch --show-current`
- `git rev-parse --show-toplevel`

## Scope Discipline

- Edit only files needed for the assigned task.
- Avoid unrelated refactors.
- If a conflict requires cross-branch changes, stop and ask for human guidance.

## Required Handoff

Return:
- Summary
- Files changed
- Validation results (PASS/FAIL per command)
- Risks or blockers
