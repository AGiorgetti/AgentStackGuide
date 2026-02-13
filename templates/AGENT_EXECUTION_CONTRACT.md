# Agent Execution Contract

This contract is mandatory for all coding agents working in this repository.

## Core Rules

1. Never rebase another agent branch.
2. Never force-push shared branches.
3. Commit only in your assigned branch and worktree.
4. Edit only files required for the assigned task.
5. If you hit out-of-scope conflicts, stop and report.

## Branch and Worktree Binding

Each run must define:
- Assigned branch: `<assigned-branch>`
- Assigned worktree path: `<assigned-worktree-path>`

Before committing, the agent must verify:

```bash
git branch --show-current
git rev-parse --show-toplevel
```

If either value does not match assignment, stop and report.

## Push Policy

Allowed:
- Fast-forward push to the assigned branch.

Not allowed:
- Push to any other branch.
- Force push (`--force`, `--force-with-lease`) unless human explicitly approves for the current branch.
- Branch deletion push.

## Rebase Policy

Allowed:
- Rebase assigned branch onto `origin/main` (or assigned base branch).

Not allowed:
- Rebase/cherry-pick another agent branch.

## Required Handoff

Agent must provide:
- Summary of changes
- Exact commands run for validation
- PASS/FAIL results
- Risks and follow-up TODOs
