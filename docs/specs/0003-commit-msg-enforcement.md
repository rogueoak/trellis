# 0003 - Enforce Conventional Commit messages

## Problem

`guidelines.md` now requires Conventional Commit messages, but nothing enforces it, so the rule
rides on memory. Trellis should ship an automatic check that every adopting repo (and this one)
gets.

## Outcome

- Trellis ships a `commit-msg` hook that rejects a commit whose subject is not a Conventional
  Commit, with an error that explains the format.
- `/trellis-install` installs it into the repo's git hooks (chaining onto any existing
  `commit-msg` hook); `/trellis-update` refreshes it.
- This repo enforces the rule on itself (dogfood).

## Decision: dependency-free hook, not off-the-shelf

Trellis installs into repos of any stack, so the checker must add no runtime. Off-the-shelf
options do not fit:

- **husky** sets `core.hooksPath` to `.husky/_`, which Git treats as a hard override of
  `.git/hooks/` - so it would silently disable Spectra's reflection `pre-commit`. It also needs
  Node and a `package.json`. Rejected.
- **commitlint** needs Node (>= 22.12) and effectively a `package.json`; on Node 24 it errors in
  a repo that has none. Breaks the moment Trellis lands in a non-Node repo. Rejected as the
  universal default.
- **Static binaries** (`committed`, `convco`) are runtime-free and Conventional-Commits-aware,
  but require each developer to install the binary. More friction than a copied script.

So Trellis ships a small POSIX `sh` `commit-msg` hook (own the regex), matching how it and
Spectra already install hooks. A side lesson: *any* `core.hooksPath`-based manager (husky,
lefthook) shadows `.git/hooks/`, so install must target the resolved hooks dir and detect when
`core.hooksPath` points elsewhere.

## Scope

**In**

- `trellis/hooks/commit-msg` - the check: allowed `type`, optional `(scope)`, optional `!`,
  then `: subject`. Passes merge / revert / `fixup!` / `squash!` auto-messages so it never blocks
  normal git flows.
- Install/update skills install or refresh the hook into the resolved hooks dir, copying (not
  symlinking) and chaining if a non-Trellis `commit-msg` hook already exists - mirroring the way
  Spectra installs its `pre-commit` reflection hook.
- Install/update detect a set `core.hooksPath` (a hook manager like husky/lefthook) and warn that
  the copied hook may be shadowed, so the check never silently no-ops.
- Dogfood: install the hook into this repo.

**Out**

- CI commit-lint (Trellis has no CI yet; a later change can add CI and reuse this same script).
- PR-title linting.

## Approach

- The hook is a POSIX `sh` script: read the commit-message file (`$1`), take the first
  non-comment line, test it against the Conventional Commits pattern, and exit non-zero with
  actionable guidance on failure.
- Allowed types: `feat fix docs chore refactor test build ci perf style revert`. Allow an
  optional `(scope)` and an optional `!` (breaking change).
- Skip enforcement for merge commits and git's auto `fixup!` / `squash!` / `revert` subjects, so
  rebases and reverts are not blocked.
- Install logic mirrors the existing reflection-hook handling: no hook present -> copy ours; a
  foreign hook present -> copy ours to `trellis-commit-msg` and chain a guarded call. Resolve the
  hooks dir with `git rev-parse --git-path hooks` (works with `core.hooksPath` and worktrees).
- The same script is reusable by CI later, unchanged.

## Risks

- A blocking hook frustrates if it is too strict: keep the allowed set broad and the error
  message clear. Local hooks are not committed, so they only protect repos that ran install or
  update; document that, and note CI as the eventual gap-filler.

## Acceptance

- [ ] `trellis/hooks/commit-msg` rejects "added a flag" and accepts "feat(install): add a flag",
      "fix: handle empty input", "chore!: drop node 18", and merge / revert / fixup subjects.
- [ ] `/trellis-install` installs it (chaining onto a pre-existing `commit-msg` hook);
      `/trellis-update` refreshes it.
- [ ] This repo's `.git/hooks/commit-msg` enforces the rule (dogfood).
- [ ] Install/update warn when `core.hooksPath` is set so the hook is not silently shadowed.
- [ ] The hook is dependency-free (POSIX `sh` + `grep`); no Node/Python/binary required.
- [ ] No em/en dashes in shipped text.
