# Git Worktree + Agents Quickstart (Commands Only)

Use this when you want the shortest path from idea to merge/discard.

---

## 0) Variables

```bash
# run from repo root
export BASE=develop
export WT_ROOT=../myapp-worktrees
export TASK1=codex-fix-auth
export TASK2=claude-add-metrics
export BR1=feat/$TASK1
export BR2=feat/$TASK2
```

---

## 1) Sync and Create Worktrees

```bash
git fetch --all --prune
mkdir -p "$WT_ROOT"

git worktree add -b "$BR1" "$WT_ROOT/$TASK1" "$BASE"
git worktree add -b "$BR2" "$WT_ROOT/$TASK2" "$BASE"

git worktree list
```

---

## 2) Run Agents in Parallel

Terminal A:

```bash
cd "$WT_ROOT/$TASK1"
# start Codex for task 1
```

Terminal B:

```bash
cd "$WT_ROOT/$TASK2"
# start Claude Code for task 2
```

---

## 3) Human Review

```bash
cd -  # back to repo root
git fetch --all --prune

git log --oneline --decorate "$BASE..$BR1"
git log --oneline --decorate "$BASE..$BR2"

git diff --stat "$BASE..$BR1"
git diff --stat "$BASE..$BR2"
```

Run validation in each worktree:

```bash
cd "$WT_ROOT/$TASK1"
# tests/lint/build

cd "$WT_ROOT/$TASK2"
# tests/lint/build
```

---

## 4A) Merge Accepted Branch

```bash
cd ~/src/myapp
git checkout "$BASE"
git pull --ff-only
git merge --no-ff "$BR1"
git push origin "$BASE"
```

---

## 4B) Discard Rejected Branch

```bash
cd ~/src/myapp
git worktree remove "$WT_ROOT/$TASK2"
git branch -D "$BR2"
git push origin --delete "$BR2"   # only if pushed before
```

---

## 5) Cleanup

```bash
git worktree prune
git worktree list
```
