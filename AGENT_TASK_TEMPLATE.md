# Agent Task Template (Codex / Claude Code)

Use this template when assigning a task to an agent in a dedicated worktree.

---

## Task Metadata

- Agent: `Codex` or `Claude Code`
- Branch: `feat/<agent>-<task>`
- Worktree path: `../<repo>-worktrees/<agent>-<task>`
- Base branch: `main`
- Deadline: `<date/time>`

---

## Objective

Describe the exact outcome expected in 2-5 lines.

Example:
Implement retry logic for token refresh failures in auth middleware and add tests for timeout and 401 retry paths.

---

## Scope

- In scope:
  - `<file/path/or/module>`
  - `<specific behavior>`
- Out of scope:
  - `<refactors>`
  - `<dependency upgrades>`

---

## Constraints

- Keep changes minimal and task-focused.
- Do not modify unrelated files.
- Follow existing code style and patterns.
- Do not force-push.
- Do not change branch name.

---

## Required Validation

Run and report output for:

```bash
# example
npm test
npm run lint
npm run build
```

If a command fails:
- Include error output
- Explain likely cause
- Propose next action

---

## Deliverables

1. One or more logical commits on assigned branch.
2. Short summary with:
   - What changed
   - Why
   - Risk areas
3. Test/lint/build results (exact commands and outcomes).
4. Any follow-up tasks as explicit TODO items.

---

## Hand-off Format

Use this structure in final response:

```text
Summary:
- ...

Commits:
- <sha> <message>

Validation:
- <command>: PASS/FAIL
- <command>: PASS/FAIL

Risks:
- ...

TODO:
- ...
```
