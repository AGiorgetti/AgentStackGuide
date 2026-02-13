# Agent Stack Guide Index

This repository is a playbook for safely running multiple coding agents in parallel with Git worktrees.
Use this index as a reading and execution order so setup, guardrails, and review steps stay consistent.

Suggested path:
1. Read `GUIDE.md` for the full model and workflow.
2. Apply repository configuration from `AGENT_CONFIGURATION_GUIDE.md`.
3. Run from `QUICKSTART_COMMANDS.md` or `GITHUB_PR_WORKFLOW.md`.
4. Make merge/discard decisions with `REVIEW_MERGE_OR_DISCARD.md`.

## 1. Start Here

1. `GUIDE.md`
Purpose: full conceptual + practical walkthrough of Git worktrees with multiple agents.

## 2. Prepare Work Assignment

1. `AGENT_CONFIGURATION_GUIDE.md`
Purpose: exact mapping of which agent uses which instruction files.

## 3. Execute Quickly

1. `QUICKSTART_COMMANDS.md`
Purpose: minimal command sequence for setup, parallel work, review, merge/discard.

## 4. If Using GitHub PR Gates

1. `GITHUB_PR_WORKFLOW.md`
Purpose: protected branch + required checks + approval workflow.

## 5. Final Human Decision Gate

1. `REVIEW_MERGE_OR_DISCARD.md`
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

1. `templates/install-manifest.txt`
Purpose: canonical file list used by both bootstrap scripts.

1. `scripts/setup-agent-guardrails.sh`
Purpose: one-command bootstrap for Linux/macOS/Git Bash.

1. `scripts/setup-agent-guardrails.ps1`
Purpose: one-command bootstrap for PowerShell on Windows.
