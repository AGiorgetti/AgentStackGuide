# Git Worktree Operations Skill

Expert guidance for Git worktree operations and standard Git workflows in multi-agent environments.

## Overview

This skill provides comprehensive knowledge for:
- **Worktree operations**: Creating and managing Git worktrees for parallel agent work
- **Standard Git operations**: All essential Git commands for daily development
- **Guardrails configuration**: Preventing unsafe operations in multi-agent setups
- **Troubleshooting**: Common issues and their solutions
- **Best practices**: Safe workflows for branch management and collaboration
- **Conflict resolution**: Handling merge and rebase conflicts

## How to Use

### In Copilot Chat

The skill is automatically available for both worktree and standard Git questions:

**Worktree questions**:
- "How do I create a worktree for a new agent task?"
- "Set up guardrails for my current worktree"
- "Why is my pre-commit hook not blocking commits?"
- "Clean up the completed worktree in ../myapp-worktrees/codex-fix-auth"

**Standard Git questions**:
- "How do I create a new feature branch?"
- "Show me how to rebase my branch onto main"
- "I need to undo my last commit but keep the changes"
- "How do I resolve merge conflicts?"
- "What's the difference between merge and rebase?"
- "How can I view the history of a specific file?"

### Bundled Scripts

This skill includes three helper scripts:

#### 1. `quick-worktree.sh`
Quickly create and configure a new worktree with guardrails.

```bash
# Create worktree for Codex task
./.github/skills/git-worktree-ops/quick-worktree.sh codex fix-auth

# Create worktree from main instead of develop
./.github/skills/git-worktree-ops/quick-worktree.sh claude add-metrics main
```

**What it does**:
- Creates worktree at `../<repo>-worktrees/<agent>-<task>`
- Creates branch `feat/<agent>-<task>`
- Sets up metadata files for hook enforcement
- Configures safe git defaults

#### 2. `verify-guardrails.sh`
Verify that guardrails are properly configured in a worktree.

```bash
# Check current worktree
./.github/skills/git-worktree-ops/verify-guardrails.sh

# Check specific worktree
./.github/skills/git-worktree-ops/verify-guardrails.sh ../myapp-worktrees/codex-fix-auth
```

**What it checks**:
- ✓ Pre-commit and pre-push hooks are executable
- ✓ Metadata files exist and match current state
- ✓ Git config has safe defaults
- ⚠️ Warnings for mismatches or missing recommendations

#### 3. `cleanup-worktree.sh`
Clean up completed or abandoned worktrees.

```bash
# Remove worktree only
./.github/skills/git-worktree-ops/cleanup-worktree.sh ../myapp-worktrees/codex-fix-auth

# Remove worktree and delete branch
./.github/skills/git-worktree-ops/cleanup-worktree.sh ../myapp-worktrees/codex-fix-auth --delete-branch

# Remove worktree, delete local + remote branch, force if dirty
./.github/skills/git-worktree-ops/cleanup-worktree.sh ../myapp-worktrees/codex-fix-auth \
  --delete-branch --remote --force
```

**What it does**:
- Removes worktree directory
- Optionally deletes local branch
- Optionally deletes remote branch
- Prunes stale metadata

## Quick Reference

### Essential Commands

| Task | Command |
|------|---------|
| Create worktree | `git worktree add -b feat/<agent>-<task> ../path develop` |
| List all worktrees | `git worktree list` |
| Remove worktree | `git worktree remove ../path` |
| Delete branch | `git branch -D feat/<agent>-<task>` |
| Prune metadata | `git worktree prune` |

### Set Up Guardrails

```bash
# In the worktree directory
GIT_DIR="$(git rev-parse --git-dir)"
printf '%s\n' "feat/<agent>-<task>" > "$GIT_DIR/agent-expected-branch"
printf '%s\n' "$(pwd -P)" > "$GIT_DIR/agent-expected-worktree"
git config --local push.default current
git config --local pull.ff only
```

Or use the `quick-worktree.sh` script to do this automatically.

## Common Workflows

### Full Setup for Three Agents

```bash
# Create worktrees
git worktree add -b feat/codex-fix-auth ../myapp-worktrees/codex-fix-auth develop
git worktree add -b feat/claude-add-metrics ../myapp-worktrees/claude-add-metrics develop
git worktree add -b feat/copilot-docs ../myapp-worktrees/copilot-docs develop

# Configure guardrails (easier with script)
./.github/skills/git-worktree-ops/quick-worktree.sh codex fix-auth
./.github/skills/git-worktree-ops/quick-worktree.sh claude add-metrics
./.github/skills/git-worktree-ops/quick-worktree.sh copilot docs
```

### Merge and Clean Up

```bash
# Review and merge
git log --oneline develop..feat/codex-fix-auth
git checkout develop
git merge --no-ff feat/codex-fix-auth

# Clean up
./.github/skills/git-worktree-ops/cleanup-worktree.sh \
  ../myapp-worktrees/codex-fix-auth --delete-branch
```

### Discard Failed Work

```bash
# Remove everything
./.github/skills/git-worktree-ops/cleanup-worktree.sh \
  ../myapp-worktrees/claude-add-metrics \
  --delete-branch --remote --force
```

## Troubleshooting

### Hooks Not Working

```bash
# Verify configuration
./.github/skills/git-worktree-ops/verify-guardrails.sh

# If errors found, fix metadata
GIT_DIR="$(git rev-parse --git-dir)"
printf '%s\n' "$(git branch --show-current)" > "$GIT_DIR/agent-expected-branch"
printf '%s\n' "$(pwd -P)" > "$GIT_DIR/agent-expected-worktree"

# Reinstall hooks if needed
cd /path/to/AgentStackGuide
./scripts/setup-agent-guardrails.sh --target /path/to/your-repo --guardrails on --force
```

### Stale Worktree Metadata

```bash
# Clean up
git worktree prune

# List what remains
git worktree list
```

### Conflicts Between Agent Branches

See the detailed conflict resolution strategy in [SKILL.md](SKILL.md#conflict-resolution).

## Installation

The skill is automatically available when the `.github/skills/` directory is present in your workspace.

To make scripts executable:

```bash
chmod +x .github/skills/git-worktree-ops/*.sh
```

## Related Documentation

- [GUIDE.md](../../../GUIDE.md) - Full worktree workflow guide
- [AGENT_CONFIGURATION_GUIDE.md](../../../AGENT_CONFIGURATION_GUIDE.md) - Agent setup
- [QUICKSTART_COMMANDS.md](../../../QUICKSTART_COMMANDS.md) - Command reference
