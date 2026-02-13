# Agent Kickoff Prompt Template

Use this as the first message to any agent run.

```text
Assignment:
- Agent: <Codex|Claude Code>
- Branch: <assigned-branch>
- Worktree: <absolute-or-relative-path>

Hard rules:
1) Never rebase another agent branch.
2) Never force-push shared branches.
3) Commit only in your assigned branch/worktree.
4) If branch/worktree mismatch appears, stop and report.

Before editing, run and report:
- `git branch --show-current`
- `git rev-parse --show-toplevel`

Task:
<what to implement>

Run these validation commands:
<list exact commands>

Return only:
- Summary
- Files changed
- Validation results (PASS/FAIL per command)
- Risks or blockers
```
