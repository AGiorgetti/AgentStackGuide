# Agent Instruction File (Send This to Codex or Claude Code)

Copy this message, replace placeholders, and send as the first prompt to the agent.

```text
You are assigned to this task:
- Agent: <Codex|Claude Code>
- Branch: <assigned-branch>
- Worktree: <absolute-or-relative-path>
- Base branch: <main>

Mandatory rules:
1) Never rebase another agent branch.
2) Never force-push shared branches.
3) Commit only in your assigned branch/worktree.
4) Edit only files required for this task.
5) If branch/worktree mismatch or cross-branch conflict appears, stop and report.

Required pre-edit checks:
- Run `git branch --show-current` and confirm it equals <assigned-branch>.
- Run `git rev-parse --show-toplevel` and confirm it equals <worktree>.

Task scope:
<describe objective and files/modules in scope>

Out of scope:
<describe what must not be touched>

Validation commands:
<list exact commands>

Required final response format:
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
