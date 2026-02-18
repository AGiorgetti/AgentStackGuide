# AgentStackGuide Workspace Instructions

## Project Overview

This is a **documentation and automation repository** for safely running multiple AI coding agents in parallel using Git worktrees. It provides templates, scripts, and workflows—not a project with build/test commands.

## Core Concepts

**Git Worktree Isolation**: One worktree per agent/task prevents interference while sharing a single `.git` database.

**Two-Layer Guardrails**:
- **Policy**: Instruction files (AGENTS.md, CLAUDE.md, .github/copilot-instructions.md)
- **Technical**: Git hooks (pre-commit, pre-push) that block wrong-branch commits/pushes

**Hook Dispatcher Pattern**: When installing into repos with existing hooks, the installer:
1. Backs up original to `.git/hooks/<hook>.orig`
2. Creates `agent-guardrails-<hook>` with template logic
3. Installs dispatcher at `.git/hooks/<hook>` that runs both

## Critical Rules When Editing This Repo

### 1. Manifest Must Stay in Sync
When adding/removing files in [templates/](../templates/):
- **ALWAYS** update [templates/install-manifest.txt](../templates/install-manifest.txt)
- Scripts read this manifest as source of truth
- Missing entries = files won't be installed

### 2. Script Parity Required
Changes to installation logic **must** be kept in sync across:
- [scripts/setup-agent-guardrails.sh](../scripts/setup-agent-guardrails.sh) (Bash)
- [scripts/setup-agent-guardrails.ps1](../scripts/setup-agent-guardrails.ps1) (PowerShell)

Both scripts must produce identical results on their respective platforms.

### 3. Hook Compatibility
Git hooks in [templates/.githooks/](../templates/.githooks/) must:
- Use POSIX-compliant Bash (runs in Git Bash on Windows)
- Start with `#!/usr/bin/env bash` and `set -euo pipefail`
- Check for metadata files: `.git/agent-expected-branch`, `.git/agent-expected-worktree`

## File Organization

### Agent-Specific Instructions
- [templates/AGENTS.md](../templates/AGENTS.md) → Codex
- [templates/CLAUDE.md](../templates/CLAUDE.md) → Claude Code
- [templates/.github/copilot-instructions.md](../templates/.github/copilot-instructions.md) → GitHub Copilot

### Shared Contract Files
- [templates/AGENT_EXECUTION_CONTRACT.md](../templates/AGENT_EXECUTION_CONTRACT.md) → Core rules for all agents
- [templates/AGENT_KICKOFF_PROMPT.md](../templates/AGENT_KICKOFF_PROMPT.md) → Reusable first message template

### Technical Guardrails
- [templates/.githooks/pre-commit](../templates/.githooks/pre-commit) → Installed to `.git/hooks/pre-commit`
- [templates/.githooks/pre-push](../templates/.githooks/pre-push) → Installed to `.git/hooks/pre-push`

### Installation Manifest
- [templates/install-manifest.txt](../templates/install-manifest.txt) → Canonical file list (must update when changing templates)

## Naming Conventions

**Branches**: `feat/<agent>-<task>` (e.g., `feat/codex-fix-auth`)

**Worktree folders**: `<agent>-<task>` (matches branch without `feat/`)

**Documentation style**:
- Numbered sections with subsections
- Command blocks ready for copy/paste
- Explicit "Allowed/Not allowed" sections
- Terminal examples with variable substitution

## Common Pitfalls

1. **Adding template without manifest update**: File won't be installed by scripts
2. **Breaking script parity**: One platform works, other fails
3. **Non-POSIX hooks**: Bash script works on Unix but breaks in Git Bash on Windows
4. **Placeholder drift**: [AGENT_KICKOFF_PROMPT.md](../templates/AGENT_KICKOFF_PROMPT.md) has placeholders that must match documentation
5. **Missing chmod**: If copying hooks manually (not via scripts), must `chmod +x`
6. **Path separator mismatch**: Manifest uses `/`, PowerShell converts to `\` internally

## Quick Reference Commands

**Test installer (Bash)**:
```bash
./scripts/setup-agent-guardrails.sh --target /tmp/test-repo --guardrails on
```

**Test installer (PowerShell)**:
```powershell
.\scripts\setup-agent-guardrails.ps1 -TargetRepo C:\Temp\test-repo -Guardrails on
```

**Verify manifest syntax**:
```bash
# Must be relative paths, forward slashes, no leading/trailing whitespace
cat templates/install-manifest.txt
```

## When Making Changes

**Adding a new template**:
1. Create file in [templates/](../templates/)
2. Add relative path to [templates/install-manifest.txt](../templates/install-manifest.txt)
3. Verify both installers copy it correctly

**Modifying installer logic**:
1. Edit both [setup-agent-guardrails.sh](../scripts/setup-agent-guardrails.sh) and [setup-agent-guardrails.ps1](../scripts/setup-agent-guardrails.ps1)
2. Test on both Unix-like OS and Windows
3. Ensure output messages match (`COPY`, `SKIP`, `BACKUP`, etc.)

**Updating hooks**:
1. Edit [templates/.githooks/pre-commit](../templates/.githooks/pre-commit) or [templates/.githooks/pre-push](../templates/.githooks/pre-push)
2. Test in Git Bash on Windows (most restrictive environment)
3. Verify metadata file checks work correctly

**Changing documentation**:
1. Maintain numbered structure and command examples
2. Update cross-references if file names change
3. Keep [README.md](../README.md) and [INDEX.md](../INDEX.md) aligned

## Key Files for Reference

- [GUIDE.md](../GUIDE.md) → Full workflow walkthrough
- [AGENT_CONFIGURATION_GUIDE.md](../AGENT_CONFIGURATION_GUIDE.md) → Agent-to-file mapping
- [QUICKSTART_COMMANDS.md](../QUICKSTART_COMMANDS.md) → Command-only reference
- [REVIEW_MERGE_OR_DISCARD.md](../REVIEW_MERGE_OR_DISCARD.md) → Human review checklist
- [templates/install-manifest.txt](../templates/install-manifest.txt) → Source of truth for installation
