# 0003 - Enforce Conventional Commit messages (plan)

Source: spec `0003`. Build in worktree `.worktrees/commit-msg-hook` on branch `commit-msg-hook`.
Dependency-free POSIX hook; install/update wire it in and detect `core.hooksPath`. Review with
engineer / tester / security personas (consumer-run script + logic + behavior).

## Steps

1. **Ship the hook** `trellis/hooks/commit-msg` - POSIX `sh` + `grep -E`. Reads `$1`, takes the
   first non-comment, non-blank line, skips `Merge`/`Revert`/`fixup!`/`squash!`/`amend!`, and
   validates `type(scope)?!?: subject` for the allowed types. Exits 1 with an actionable message.

2. **Wire into install** (`trellis-install`): resolve `HOOKS="$(git rev-parse --git-path hooks)"`;
   if no `commit-msg` hook, copy ours; if a foreign one exists, copy ours to
   `trellis-commit-msg` and chain a guarded call (mirror the Spectra `pre-commit` pattern). Warn
   if `git config core.hooksPath` is set (the copied hook may be shadowed).

3. **Wire into update** (`trellis-update`): refresh the copied hook the same way; same
   `core.hooksPath` warning.

4. **Dogfood**: install the hook into this repo's `.git/hooks/commit-msg`.

5. **README**: note the commit-msg hook under what lands in a consumer repo.

6. **Verify** (the test suite for this change):
   - Hook accepts `feat(install): x`, `fix: y`, `chore!: z`, and merge/revert/fixup subjects;
     rejects `added a flag` and an empty/junk subject.
   - Install in a scratch repo creates `.git/hooks/commit-msg`; chaining onto a pre-existing hook
     keeps both; `core.hooksPath` set -> warning emitted.
   - No em/en dashes in shipped text.

7. **Reflect**: `features.md` (commit-msg enforcement), `architecture.md` (hooks shipped +
   resolved-dir/`core.hooksPath` handling), `learnings.md` (hook managers shadow `.git/hooks`).

## Files touched

`trellis/hooks/commit-msg`, both skill `SKILL.md`s, `README.md`, this repo's
`.git/hooks/commit-msg` (dogfood, untracked), `docs/overview/*`.
