# Git Worktree Guide for Parallel Agent Development (Codex + Claude Code + GitHub Copilot)

This guide shows a practical workflow for using `git worktree` so multiple coding agents can work in parallel without stepping on each other.

You will learn:
- What Git worktrees are
- How to create one worktree per agent/task
- How to run Codex, Claude Code, and GitHub Copilot in different worktrees
- How a human reviews results and chooses to merge or discard

---

## 1. What a Git Worktree Is

A Git worktree is an additional checked-out working directory connected to the same Git repository.

With worktrees, you can:
- Have multiple branches checked out at the same time
- Avoid constantly switching branches in one folder
- Isolate each agent task in its own directory
- Review and merge each agent result independently

Think of it as:
- One shared `.git` object database
- Multiple working folders (one per branch/task)

---

## 2. Why Worktrees Are Ideal for AI Agents

Agents are fast, but can interfere with each other if they share one folder.

Using one worktree per agent gives you:
- Isolation: each agent edits only its own branch and files
- Reproducibility: task context remains stable in each folder
- Easier review: each PR/branch maps to one task
- Safe cleanup: discard one failed branch without affecting others

---

## 3. Recommended Directory Layout

Assume your primary repo is here:

```text
~/src/myapp
```

Create a sibling directory for worktrees:

```text
~/src/myapp-worktrees/
  codex-fix-auth/
  claude-add-metrics/
  copilot-docs/
```

This keeps your primary repo clean and makes cleanup easier.

---

## 4. One-Time Setup

Run in your primary repo root:

```bash
git fetch --all --prune
git status
```

Make sure:
- Working tree is clean (or intentionally dirty)
- You know your base branch (`develop` used below)

Optional quality-of-life aliases:

```bash
git config alias.wt "worktree"
git config alias.wtl "worktree list"
```

---

## 5. Create Worktrees for Multiple Agents

### Example: three parallel tasks

- Task A for Codex: fix auth retry bug
- Task B for Claude Code: add request metrics
- Task C for GitHub Copilot: improve API error docs

From the primary repo root:

```bash
mkdir -p ../myapp-worktrees

git worktree add -b feat/codex-fix-auth ../myapp-worktrees/codex-fix-auth develop
git worktree add -b feat/claude-add-metrics ../myapp-worktrees/claude-add-metrics develop
git worktree add -b feat/copilot-docs ../myapp-worktrees/copilot-docs develop
```

What this does:
- Creates new branches from `develop`
- Checks each branch out into its own folder
- Registers both folders with Git worktree metadata

Verify:

```bash
git worktree list
```

---

## 6. Assign Work to Each Agent

### 6.1 Codex worktree

```bash
cd ../myapp-worktrees/codex-fix-auth
```

Give Codex:
- Exact task scope
- Constraints (tests, style, files to avoid)
- Required output (commit(s), summary, test results)

### 6.2 Claude Code worktree

In another terminal:

```bash
cd ../myapp-worktrees/claude-add-metrics
```

Give Claude Code:
- Clear acceptance criteria
- Boundaries and non-goals
- Required verification steps

### 6.3 GitHub Copilot worktree

In another terminal/editor workspace:

```bash
cd ../myapp-worktrees/copilot-docs
```

Give GitHub Copilot:
- A focused task prompt
- Exact files to edit
- Required validation commands

Important rules for all agents:
- Do not rebase other agent branches
- Do not force-push shared branches
- Commit only in their assigned branch/worktree

---

## 7. Agent Execution Contract (Required)

Use this contract for every task so agents do not step on each other.

### 7.1 Non-negotiable rules

1. Agent must never rebase another agent branch.
2. Agent must never force-push shared branches.
3. Agent must commit only in its assigned branch and worktree.
4. Agent can edit only task-relevant files.
5. Agent must run tests/lint and report exact command outputs.

### 7.2 Bind each worktree to one branch

Run once inside each agent worktree before starting the agent:

```bash
# example for Codex worktree
cd ../myapp-worktrees/codex-fix-auth
git checkout feat/codex-fix-auth

# safer defaults
git config --local push.default current
git config --local pull.ff only

# bind this worktree to this branch
GIT_DIR="$(git rev-parse --git-dir)"
printf '%s\n' "feat/codex-fix-auth" > "$GIT_DIR/agent-expected-branch"
printf '%s\n' "$(pwd -P)" > "$GIT_DIR/agent-expected-worktree"
```

Repeat with the Claude and Copilot worktree/branch values.

### 7.3 Install local guardrail hooks

From repo root, install shared hooks that enforce the contract.
You can either create them manually (below) or copy the prepared templates from `templates/.githooks/`:

```bash
mkdir -p .githooks

cat > .githooks/pre-commit <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

git_dir="$(git rev-parse --git-dir)"
expected_branch_file="$git_dir/agent-expected-branch"
expected_worktree_file="$git_dir/agent-expected-worktree"

[ -f "$expected_branch_file" ] || exit 0
expected_branch="$(cat "$expected_branch_file")"
expected_worktree="$(cat "$expected_worktree_file" 2>/dev/null || true)"

current_branch="$(git symbolic-ref --short -q HEAD || true)"
current_worktree="$(git rev-parse --show-toplevel)"

if [ "$current_branch" != "$expected_branch" ]; then
  echo "Blocked: this worktree is bound to '$expected_branch', current is '$current_branch'." >&2
  exit 1
fi

if [ -n "$expected_worktree" ] && [ "$current_worktree" != "$expected_worktree" ]; then
  echo "Blocked: commits are allowed only from '$expected_worktree'." >&2
  exit 1
fi
EOF

cat > .githooks/pre-push <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

zero="0000000000000000000000000000000000000000"
git_dir="$(git rev-parse --git-dir)"
expected_branch_file="$git_dir/agent-expected-branch"
[ -f "$expected_branch_file" ] || exit 0

expected_branch="$(cat "$expected_branch_file")"
expected_remote_ref="refs/heads/$expected_branch"

while read -r local_ref local_sha remote_ref remote_sha; do
  if [ "$remote_ref" != "$expected_remote_ref" ]; then
    echo "Blocked: this worktree can only push to '$expected_remote_ref'." >&2
    exit 1
  fi

  if [ "$local_sha" = "$zero" ]; then
    echo "Blocked: branch deletion push is not allowed from agent worktrees." >&2
    exit 1
  fi

  if [ "$remote_sha" != "$zero" ]; then
    if ! git merge-base --is-ancestor "$remote_sha" "$local_sha"; then
      echo "Blocked: non-fast-forward push detected (force push not allowed)." >&2
      exit 1
    fi
  fi
done
EOF

chmod +x .githooks/pre-commit .githooks/pre-push
git config core.hooksPath .githooks
```

What this enforces:
- Wrong branch commit in a worktree is blocked.
- Push to another branch is blocked.
- Non-fast-forward push (force push) is blocked.
- Branch deletion push from an agent worktree is blocked.

### 7.4 Rebase and update policy

Allowed:
- Rebase or merge only the current agent branch onto `develop`.

Not allowed:
- Rebasing/cherry-picking other agent branches.
- Force-pushing shared branches.

Safe sync example:

```bash
cd ../myapp-worktrees/codex-fix-auth
git fetch origin
git rebase origin/develop
```

### 7.5 Prompt guardrails for every agent run

Include this exact block in each agent prompt:

```text
You are assigned to branch <branch> in worktree <path>.
Never rebase another agent branch.
Never force push shared branches.
Commit only in your assigned branch/worktree.
If you hit a conflict outside your scope, stop and report.
```

### 7.6 Required handoff from agent

Agent must produce:
- Small logical commits
- Final change summary
- Risks and TODOs

### 7.7 Instruction files to add in each target Git repo

Add these files so all agents receive the same rules:
- `AGENT_EXECUTION_CONTRACT.md`
- `AGENTS.md` (Codex instructions)
- `CLAUDE.md` (Claude Code instructions)
- `COPILOT.md` (GitHub Copilot instructions)
- `.github/copilot-instructions.md` (GitHub Copilot native repo instructions)
- `.githooks/pre-commit`
- `.githooks/pre-push`

Templates are provided in this guide repo:
- `templates/AGENT_EXECUTION_CONTRACT.md`
- `templates/AGENTS.md`
- `templates/CLAUDE.md`
- `templates/COPILOT.md`
- `templates/AGENT_KICKOFF_PROMPT.md`
- `templates/.github/copilot-instructions.md`
- `templates/.githooks/pre-commit`
- `templates/.githooks/pre-push`

### 7.8 Install templates in a target repo

Example copy from this guide repo into another repository:

```bash
# GUIDE_REPO = this repository (AgentStackGuide)
# TARGET_REPO = repository where agents will work
GUIDE_REPO=/path/to/AgentStackGuide
TARGET_REPO=/path/to/your-repo

cp "$GUIDE_REPO/templates/AGENT_EXECUTION_CONTRACT.md" "$TARGET_REPO/AGENT_EXECUTION_CONTRACT.md"
cp "$GUIDE_REPO/templates/AGENTS.md" "$TARGET_REPO/AGENTS.md"
cp "$GUIDE_REPO/templates/CLAUDE.md" "$TARGET_REPO/CLAUDE.md"
cp "$GUIDE_REPO/templates/COPILOT.md" "$TARGET_REPO/COPILOT.md"
cp "$GUIDE_REPO/templates/AGENT_KICKOFF_PROMPT.md" "$TARGET_REPO/AGENT_KICKOFF_PROMPT.md"
mkdir -p "$TARGET_REPO/.github"
cp "$GUIDE_REPO/templates/.github/copilot-instructions.md" "$TARGET_REPO/.github/copilot-instructions.md"

mkdir -p "$TARGET_REPO/.githooks"
cp "$GUIDE_REPO/templates/.githooks/pre-commit" "$TARGET_REPO/.githooks/pre-commit"
cp "$GUIDE_REPO/templates/.githooks/pre-push" "$TARGET_REPO/.githooks/pre-push"
chmod +x "$TARGET_REPO/.githooks/pre-commit" "$TARGET_REPO/.githooks/pre-push"

cd "$TARGET_REPO"
git config core.hooksPath .githooks
```

Bootstrap option (recommended):

```bash
# Bash
./scripts/setup-agent-guardrails.sh --target /path/to/your-repo
./scripts/setup-agent-guardrails.sh --target /path/to/your-repo --force
```

```powershell
# PowerShell
.\scripts\setup-agent-guardrails.ps1 -TargetRepo C:\path\to\your-repo
.\scripts\setup-agent-guardrails.ps1 -TargetRepo C:\path\to\your-repo -Force
```

### 7.9 Configure Codex (per worktree)

1. Open terminal in Codex worktree:
   - `cd ../myapp-worktrees/codex-fix-auth`
2. Confirm branch/worktree binding:
   - `git checkout feat/codex-fix-auth`
   - `git branch --show-current`
   - `git rev-parse --show-toplevel`
3. Write guardrail metadata for hooks:
   - `GIT_DIR="$(git rev-parse --git-dir)"`
   - `printf '%s\n' "feat/codex-fix-auth" > "$GIT_DIR/agent-expected-branch"`
   - `printf '%s\n' "$(pwd -P)" > "$GIT_DIR/agent-expected-worktree"`
4. Send kickoff instructions using `templates/AGENT_KICKOFF_PROMPT.md` with filled placeholders.
5. Require Codex to report pre-edit check output before code changes.

### 7.10 Configure Claude Code (per worktree)

1. Open terminal in Claude worktree:
   - `cd ../myapp-worktrees/claude-add-metrics`
2. Confirm branch/worktree binding:
   - `git checkout feat/claude-add-metrics`
   - `git branch --show-current`
   - `git rev-parse --show-toplevel`
3. Write guardrail metadata for hooks:
   - `GIT_DIR="$(git rev-parse --git-dir)"`
   - `printf '%s\n' "feat/claude-add-metrics" > "$GIT_DIR/agent-expected-branch"`
   - `printf '%s\n' "$(pwd -P)" > "$GIT_DIR/agent-expected-worktree"`
4. Ensure `CLAUDE.md` exists at repo root.
5. Send kickoff instructions using `templates/AGENT_KICKOFF_PROMPT.md` with filled placeholders.

### 7.11 Configure GitHub Copilot (per worktree)

1. Open terminal/editor in Copilot worktree:
   - `cd ../myapp-worktrees/copilot-docs`
2. Confirm branch/worktree binding:
   - `git checkout feat/copilot-docs`
   - `git branch --show-current`
   - `git rev-parse --show-toplevel`
3. Write guardrail metadata for hooks:
   - `GIT_DIR="$(git rev-parse --git-dir)"`
   - `printf '%s\n' "feat/copilot-docs" > "$GIT_DIR/agent-expected-branch"`
   - `printf '%s\n' "$(pwd -P)" > "$GIT_DIR/agent-expected-worktree"`
4. Ensure `COPILOT.md` and `.github/copilot-instructions.md` exist in the repository.
5. Start Copilot Chat from that worktree folder and send kickoff instructions using `templates/AGENT_KICKOFF_PROMPT.md`.

### 7.12 Instruction file to send agents

Use this file for all agents:
- `templates/AGENT_KICKOFF_PROMPT.md`

Always fill these placeholders before sending:
- `<Codex|Claude Code|GitHub Copilot>`
- `<assigned-branch>`
- `<absolute-or-relative-path>`
- `<what to implement>`
- `<list exact commands>`

This contract makes human review faster and safer.

---

## 8. Human Review Workflow

After agents finish, the human performs review before any merge.

### 8.1 Inspect branch changes

From primary repo:

```bash
git fetch --all --prune
git log --oneline --decorate develop..feat/codex-fix-auth
git log --oneline --decorate develop..feat/claude-add-metrics
git log --oneline --decorate develop..feat/copilot-docs
```

Review diff quality:

```bash
git diff --stat develop..feat/codex-fix-auth
git diff --stat develop..feat/claude-add-metrics
git diff --stat develop..feat/copilot-docs
```

### 8.2 Check out each worktree and validate

```bash
cd ../myapp-worktrees/codex-fix-auth
# run tests/lint/build for your stack

cd ../myapp-worktrees/claude-add-metrics
# run tests/lint/build for your stack

cd ../myapp-worktrees/copilot-docs
# run tests/lint/build for your stack
```

### 8.3 Review checklist

- Correctness: Does it solve the stated task?
- Scope: Any unrelated changes?
- Safety: Any security/perf regressions?
- Maintainability: Clear code and tests?
- Compatibility: No breaking changes unless intended?

---

## 9. Decision Point: Merge or Discard

### Option A: Merge accepted work

If branch is good:

```bash
cd ~/src/myapp
git checkout develop
git pull --ff-only
git merge --no-ff feat/codex-fix-auth
git push origin develop
```

Repeat for other accepted branches.

If using pull requests, open PR instead and merge via platform UI.

### Option B: Discard rejected work

If branch is not acceptable:

```bash
cd ~/src/myapp
git worktree remove ../myapp-worktrees/claude-add-metrics
git branch -D feat/claude-add-metrics
```

If remote branch exists:

```bash
git push origin --delete feat/claude-add-metrics
```

---

## 10. Cleanup Completed Worktrees

After merging or discarding:

```bash
git worktree list
git worktree prune
```

Remove stale folders if needed:

```bash
rm -rf ../myapp-worktrees/codex-fix-auth
```

Then ensure only active worktrees remain.

---

## 11. Scaling to Many Agents

For 3+ agents, standardize:
- Branch naming: `feat/<agent>-<task>`
- Folder naming: `<agent>-<task>`
- Task template (see `AGENT_TASK_TEMPLATE.md`)
- Human review checklist (see `REVIEW_CHECKLIST.md`)

Practical orchestration tips:
- Keep tasks independent to reduce merge conflicts
- Prefer smaller task slices (1-3 hours each)
- Merge frequently to reduce branch drift from `develop`

---

## 12. Conflict Handling Strategy

If two agent branches touch same files:

1. Pick one branch to merge first.
2. Rebase or merge `develop` into the second branch.
3. Resolve conflicts manually (human-owned).
4. Re-run validation.
5. Merge second branch.

Do not ask multiple agents to auto-resolve the same conflict blindly.

---

## 13. End-to-End Example Script

```bash
# from primary repo
git fetch --all --prune
mkdir -p ../myapp-worktrees

# create three agent worktrees
git worktree add -b feat/codex-fix-auth ../myapp-worktrees/codex-fix-auth develop
git worktree add -b feat/claude-add-metrics ../myapp-worktrees/claude-add-metrics develop
git worktree add -b feat/copilot-docs ../myapp-worktrees/copilot-docs develop

# ...agents work in their folders and commit...

# human review and merge one
git checkout develop
git pull --ff-only
git merge --no-ff feat/codex-fix-auth
git push origin develop

# discard the others
git worktree remove ../myapp-worktrees/claude-add-metrics
git branch -D feat/claude-add-metrics
git worktree remove ../myapp-worktrees/copilot-docs
git branch -D feat/copilot-docs

# cleanup
git worktree prune
```

---

## 14. Common Mistakes to Avoid

- Running two agents in the same worktree
- Letting agents modify unrelated files
- Skipping human verification before merge
- Keeping stale worktrees for weeks
- Large, mixed-scope branches that are hard to review

---

## 15. Quick Command Reference

```bash
# list worktrees
git worktree list

# create new worktree + branch from develop
git worktree add -b feat/task-name ../path/to/wt develop

# remove worktree
git worktree remove ../path/to/wt

# delete local branch
git branch -D feat/task-name

# prune stale worktree metadata
git worktree prune
```

For reusable prompts and review standards, see:
- `AGENT_TASK_TEMPLATE.md`
- `AGENT_INSTRUCTION_FILE.md`
- `REVIEW_CHECKLIST.md`
- `QUICKSTART_COMMANDS.md`
- `GITHUB_PR_WORKFLOW.md`
- `templates/AGENT_EXECUTION_CONTRACT.md`
- `templates/AGENTS.md`
- `templates/CLAUDE.md`
- `templates/COPILOT.md`
- `templates/AGENT_KICKOFF_PROMPT.md`
- `templates/.github/copilot-instructions.md`
- `templates/.githooks/pre-commit`
- `templates/.githooks/pre-push`
