# Git Worktree Workflow with GitHub PRs, Branch Protection, and CI Gates

This version is for teams that require pull requests and protected branches.

---

## 1. Goal

Use one worktree per agent task, then promote changes through GitHub PRs with required checks before merge.

---

## 2. Branch Protection Baseline (GitHub)

In GitHub repository settings for `main`:

- Require a pull request before merging
- Require approvals (for example, at least 1)
- Require status checks to pass before merging
- Require branch to be up to date before merging
- Include administrators (recommended)
- Restrict force pushes and direct pushes

Typical required checks:
- `lint`
- `test`
- `build`
- security scan (for example, CodeQL)

---

## 3. Create Worktrees and Branches

From repo root:

```bash
git fetch --all --prune
mkdir -p ../myapp-worktrees

git worktree add -b feat/codex-fix-auth ../myapp-worktrees/codex-fix-auth main
git worktree add -b feat/claude-add-metrics ../myapp-worktrees/claude-add-metrics main
```

---

## 4. Let Agents Work in Isolation

Terminal A:

```bash
cd ../myapp-worktrees/codex-fix-auth
# run Codex with task instructions
```

Terminal B:

```bash
cd ../myapp-worktrees/claude-add-metrics
# run Claude Code with task instructions
```

Agent constraints:
- Commit only on assigned branch
- Keep scope limited to assigned task
- Run local tests/lint/build before handoff

---

## 5. Push Branches and Open PRs

After each agent finishes:

```bash
cd ../myapp-worktrees/codex-fix-auth
git push -u origin feat/codex-fix-auth

cd ../myapp-worktrees/claude-add-metrics
git push -u origin feat/claude-add-metrics
```

Open PRs targeting `main`.

PR template should include:
- task objective
- files changed summary
- test evidence
- risk notes

---

## 6. Human Review + CI Gate

For each PR:

1. Review code and commit history.
2. Confirm CI required checks all pass.
3. Confirm PR is up to date with `main` (if required).
4. Approve or request changes.

If branch is behind:

```bash
cd ../myapp-worktrees/codex-fix-auth
git fetch origin
git rebase origin/main
git push --force-with-lease
```

Use `--force-with-lease` only on your own feature branch.

---

## 7. Decision: Merge or Discard

### Merge path

If approved and checks pass:
- Merge PR in GitHub using your chosen method:
  - merge commit
  - squash merge
  - rebase merge

Then clean up:

```bash
cd ~/src/myapp
git fetch --all --prune
git worktree remove ../myapp-worktrees/codex-fix-auth
git branch -d feat/codex-fix-auth
git worktree prune
```

### Discard path

If rejected:
- Close PR without merge
- Delete branch on GitHub

Local cleanup:

```bash
cd ~/src/myapp
git worktree remove ../myapp-worktrees/claude-add-metrics
git branch -D feat/claude-add-metrics
git fetch --prune
git worktree prune
```

---

## 8. Suggested Team Policy

- One PR = one agent task = one worktree
- Keep PR size small (prefer under ~400 changed lines when practical)
- Require at least one human approval
- Do not auto-merge agent PRs without review
- Keep an audit trail in PR descriptions and linked issues

---

## 9. Optional: Labeling Convention

Add labels to agent PRs:
- `agent:codex`
- `agent:claude`
- `risk:low|medium|high`
- `needs-human-review`

This makes filtering and governance easier.
