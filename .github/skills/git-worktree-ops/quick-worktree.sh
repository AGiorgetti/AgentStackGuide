#!/usr/bin/env bash
# Quick worktree setup with automatic guardrails configuration
# Usage: quick-worktree.sh <agent> <task> [base-branch]

set -euo pipefail

usage() {
  cat <<EOF
Usage: quick-worktree.sh <agent> <task> [base-branch]

Examples:
  quick-worktree.sh codex fix-auth
  quick-worktree.sh claude add-metrics develop
  quick-worktree.sh copilot docs main

Arguments:
  agent       Agent name (codex, claude, copilot)
  task        Task description (kebab-case)
  base-branch Base branch to branch from (default: develop)
EOF
}

if [[ $# -lt 2 ]]; then
  usage
  exit 1
fi

# Verify we're in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Error: Not in a git repository. Please run this script from within a git repository." >&2
  exit 1
fi

AGENT="$1"
TASK="$2"
BASE="${3:-develop}"

BRANCH="feat/${AGENT}-${TASK}"
WORKTREE_ROOT="../$(basename "$(pwd)")-worktrees"
WORKTREE_PATH="${WORKTREE_ROOT}/${AGENT}-${TASK}"

echo "Creating worktree setup:"
echo "  Agent:    $AGENT"
echo "  Task:     $TASK"
echo "  Branch:   $BRANCH"
echo "  Path:     $WORKTREE_PATH"
echo "  Base:     $BASE"
echo ""

# Create worktrees directory if needed
mkdir -p "$WORKTREE_ROOT"

# Create worktree
echo "Creating worktree..."
if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  echo "Branch '$BRANCH' already exists; attaching worktree to existing branch."
  git worktree add "$WORKTREE_PATH" "$BRANCH"
else
  git worktree add -b "$BRANCH" "$WORKTREE_PATH" "$BASE"
fi

# Configure guardrails
echo "Configuring guardrails..."
cd "$WORKTREE_PATH"

GIT_DIR="$(git rev-parse --git-dir)"
printf '%s\n' "$BRANCH" > "$GIT_DIR/agent-expected-branch"
printf '%s\n' "$(pwd -P)" > "$GIT_DIR/agent-expected-worktree"

# Set safe defaults
git config --local push.default current
git config --local pull.ff only

echo ""
echo "✓ Worktree created and configured!"
echo ""
echo "Verification:"
echo "  Current branch: $(git branch --show-current)"
echo "  Worktree path:  $(git rev-parse --show-toplevel)"
echo "  Expected branch: $(cat "$GIT_DIR/agent-expected-branch")"
echo "  Expected worktree: $(cat "$GIT_DIR/agent-expected-worktree")"
echo ""
echo "Next steps:"
echo "  cd $WORKTREE_PATH"
echo "  # Start your agent and begin work"
