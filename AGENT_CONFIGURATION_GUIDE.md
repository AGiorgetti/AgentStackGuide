# Agent Configuration Guide

This guide defines which instruction files are used by each agent and which ones are optional.

## Required Files (All Repos)

- `AGENT_EXECUTION_CONTRACT.md`
- `AGENT_KICKOFF_PROMPT.md`
- `.githooks/pre-commit`
- `.githooks/pre-push`

## Agent-to-File Mapping

- Codex:
  - `AGENTS.md`
  - `AGENT_EXECUTION_CONTRACT.md`
  - `AGENT_KICKOFF_PROMPT.md`
- Claude Code:
  - `CLAUDE.md`
  - `AGENT_EXECUTION_CONTRACT.md`
  - `AGENT_KICKOFF_PROMPT.md`
- GitHub Copilot:
  - `.github/copilot-instructions.md` (canonical)
  - `AGENT_EXECUTION_CONTRACT.md`
  - `AGENT_KICKOFF_PROMPT.md`

## Recommended Install

Use bootstrap scripts:

```bash
./scripts/setup-agent-guardrails.sh --target /path/to/repo
```

```powershell
.\scripts\setup-agent-guardrails.ps1 -TargetRepo C:\path\to\repo
```

Optional compatibility file:
