---
description: Guidelines for editing template files in templates/ folder
applyTo: templates/**/*.md, templates/.githooks/*
---

# Template File Editing Guidelines

When editing files in the `templates/` folder, follow these rules:

## Mandatory Steps

1. **Update the manifest**: After creating, renaming, or deleting any template file, you **MUST** update [templates/install-manifest.txt](../../templates/install-manifest.txt)
   - Add new files with their relative path (e.g., `AGENT_EXECUTION_CONTRACT.md`)
   - Remove deleted files from the manifest
   - Update paths if files are renamed or moved

2. **Maintain cross-platform compatibility**:
   - Use forward slashes `/` in manifest paths (required)
   - Avoid platform-specific syntax or commands
   - Test that both installer scripts can process the file

3. **Hook files (.githooks/)**:
   - Must use POSIX-compliant Bash (runs in Git Bash on Windows)
   - Start with `#!/usr/bin/env bash` and `set -euo pipefail`
   - Check for metadata files when appropriate:
     - `.git/agent-expected-branch`
     - `.git/agent-expected-worktree`
   - Must be executable: `chmod +x` applied by installers

4. **Placeholder consistency**:
   - Use consistent placeholder format: `<description>` (angle brackets)
   - Document all placeholders in AGENT_KICKOFF_PROMPT.md
   - Common placeholders:
     - `<Codex|Claude Code|GitHub Copilot>`
     - `<assigned-branch>`
     - `<absolute-or-relative-path>`
     - `<what to implement>`
     - `<list exact commands>`

## Template Types

- **Agent instructions**: AGENTS.md, CLAUDE.md, .github/copilot-instructions.md
- **Shared contracts**: AGENT_EXECUTION_CONTRACT.md, AGENT_KICKOFF_PROMPT.md
- **Technical guardrails**: .githooks/pre-commit, .githooks/pre-push
- **Installation control**: install-manifest.txt

## Verification Checklist

Before committing template changes:
- [ ] Manifest updated with correct relative path
- [ ] Path uses forward slashes `/`
- [ ] No leading/trailing whitespace in manifest entry
- [ ] Hook files have proper shebang and error handling
- [ ] Placeholders use `<description>` format
- [ ] Cross-references to other templates are accurate
