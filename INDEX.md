# Guide Index

This index puts the guide files in the recommended execution order.

## 1. Start Here

1. `GUIDE.md`
Purpose: full conceptual + practical walkthrough of Git worktrees with multiple agents.

## 2. Prepare Work Assignment

1. `AGENT_TASK_TEMPLATE.md`
Purpose: consistent task brief for each agent/worktree.

1. `AGENT_INSTRUCTION_FILE.md`
Purpose: copy/paste instruction message to send as first prompt to each agent.

1. `AGENT_CONFIGURATION_GUIDE.md`
Purpose: exact mapping of which agent uses which instruction files.

## 3. Execute Quickly

1. `QUICKSTART_COMMANDS.md`
Purpose: minimal command sequence for setup, parallel work, review, merge/discard.

## 4. If Using GitHub PR Gates

1. `GITHUB_PR_WORKFLOW.md`
Purpose: protected branch + required checks + approval workflow.

## 5. Final Human Decision Gate

1. `REVIEW_CHECKLIST.md`
Purpose: explicit merge-or-discard checklist and cleanup procedure.

## 6. Templates for Any Repository

1. `templates/AGENT_EXECUTION_CONTRACT.md`
Purpose: shared policy file for all agents.

1. `templates/AGENTS.md`
Purpose: repo instruction file for Codex.

1. `templates/CLAUDE.md`
Purpose: repo instruction file for Claude Code.

1. `templates/AGENT_KICKOFF_PROMPT.md`
Purpose: reusable first-message template for all agents.

1. `templates/.github/copilot-instructions.md`
Purpose: canonical GitHub Copilot repository instruction file.

1. `templates/.githooks/pre-commit`
Purpose: blocks commits from wrong branch/worktree.

1. `templates/.githooks/pre-push`
Purpose: blocks wrong-branch and non-fast-forward pushes.

1. `scripts/setup-agent-guardrails.sh`
Purpose: one-command bootstrap for Linux/macOS/Git Bash.

1. `scripts/setup-agent-guardrails.ps1`
Purpose: one-command bootstrap for PowerShell on Windows.

---

## Command Argument Order Standard

Use this order throughout:

```bash
git worktree add -b <new-branch> <worktree-path> <start-point>
```

Example:

```bash
git worktree add -b feat/codex-fix-auth ../myapp-worktrees/codex-fix-auth develop
```
