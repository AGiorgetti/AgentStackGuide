# Agent Stack Guide

`Agent Stack Guide` is a practical guide for teams that want to run multiple AI coding agents in parallel without branch collisions or unsafe Git operations.

The guide focuses on:
- Isolating each agent in its own Git worktree
- Enforcing branch/worktree safety guardrails
- Standardizing instructions for Codex, Claude Code, and GitHub Copilot
- Keeping human review as the final merge/discard control point

## What You Get

- A full workflow guide: `GUIDE.md`
- A navigation index: `INDEX.md`
- Agent/file mapping and setup model: `AGENT_CONFIGURATION_GUIDE.md`
- Commands-only quickstart: `QUICKSTART_COMMANDS.md`
- GitHub PR variant with branch protection: `GITHUB_PR_WORKFLOW.md`
- Human decision checklist: `REVIEW_MERGE_OR_DISCARD.md`
- Reusable templates and hooks in `templates/`
- Bootstrap scripts in `scripts/` for Bash and PowerShell

## Recommended Start

1. Open `INDEX.md`.
2. Follow `GUIDE.md` sections in order.
3. Install templates with:
   - `scripts/setup-agent-guardrails.sh`
   - `scripts/setup-agent-guardrails.ps1`
4. Keep guardrails `on` by default; switch `off` only for local experiments.

## Scope

This repository is documentation and automation glue for process safety. It does not include project-specific CI, test commands, or language-specific build logic.
