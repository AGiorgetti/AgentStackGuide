# GitHub Copilot Instructions

For all workflow and safety rules, follow:
- `AGENT_EXECUTION_CONTRACT.md`

Copilot-specific behavior:
- Start each task from the assigned worktree path.
- Run and report:
  - `git branch --show-current`
  - `git rev-parse --show-toplevel`
- If these do not match assignment, stop and report.

Use `AGENT_KICKOFF_PROMPT.md` as the first prompt template.
