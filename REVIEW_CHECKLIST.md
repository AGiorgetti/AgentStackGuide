# Human Review Checklist for Agent Branches

Use this checklist before merging any agent-produced branch.

---

## 1. Branch Hygiene

- [ ] Branch targets correct base (`develop` or agreed release/hotfix branch)
- [ ] Branch contains only task-related commits
- [ ] No accidental secrets or environment file changes

Commands:

```bash
git log --oneline --decorate develop..feat/<agent>-<task>
git diff --stat develop..feat/<agent>-<task>
```

---

## 2. Code Quality

- [ ] Change matches task objective
- [ ] No unrelated refactors
- [ ] Naming/readability consistent with codebase
- [ ] Error handling and edge cases considered

---

## 3. Test and Validation

- [ ] Unit/integration tests added or updated where needed
- [ ] Lint/build/tests pass locally or in CI
- [ ] Agent provided actual command outputs

---

## 4. Risk Review

- [ ] Security implications reviewed
- [ ] Performance impact acceptable
- [ ] Backward compatibility maintained (or documented)
- [ ] Observability/logging updated if behavior changed

---

## 5. Decision Matrix

Merge if:
- All required checks pass
- Scope is correct
- Risk is acceptable

Request changes if:
- Core behavior is mostly right but gaps exist

Discard if:
- Wrong scope
- Repeatedly unstable
- Higher rework cost than rewriting

---

## 6. Merge Procedure

```bash
git checkout develop
git pull --ff-only
git merge --no-ff feat/<agent>-<task>
git push origin develop
```

After merge:

```bash
git worktree remove ../<repo>-worktrees/<agent>-<task>
git branch -d feat/<agent>-<task>
git worktree prune
```

---

## 7. Discard Procedure

```bash
git worktree remove ../<repo>-worktrees/<agent>-<task>
git branch -D feat/<agent>-<task>
git push origin --delete feat/<agent>-<task>   # if pushed
git worktree prune
```

Note: if you need an audit trail, tag or archive the branch before deleting.
