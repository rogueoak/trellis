# 0004 - Build plan: install compliance pass

Implements spec `0004-install-compliance-pass.md`. Build in a worktree, test, PR, review, merge.

## Files touched

- **new** `trellis/scripts/check-compliance.sh` - the scanner (report + `--fix`).
- `trellis/skills/trellis-install/SKILL.md` - add a compliance-pass step + `--fix` passthrough.
- `trellis/skills/trellis-update/SKILL.md` - same step.
- `docs/overview/features.md`, `architecture.md`, `learnings.md` - reflect (step 6).
- Version bump (release step, after merge): the 7 manifest files at `0.1.2`.

## Steps

1. **Write `trellis/scripts/check-compliance.sh`.**
   - `set -eu`; usage `check-compliance.sh [--fix]`, run from repo root.
   - Candidate files: `git ls-files`. Skip binary with `grep -Iq .` (a file `grep -I` treats as
     binary is skipped). This also naturally skips untracked/ignored files.
   - Targets: em-dash U+2014, en-dash U+2013. Build the literal bytes once
     (`em=$(printf '\342\200\224')`, `en=$(printf '\342\200\223')`) so the script file itself
     stays ASCII and does not trip its own check.
   - Report mode (default): for each file, `grep -nF` each dash; print `file:line: <text>`.
     Track a count; exit 1 if any, 0 if clean. Print a one-line `--fix` hint when non-empty.
   - Fix mode (`--fix`): `sed` em-dash -> ` - ` and en-dash -> `-`, collapse doubled spaces the
     em swap introduces (`  ` -> ` `) only on changed lines, write back only files that changed,
     list them. Re-running must report clean.
   - Keep it POSIX `sh` + `grep`/`sed`. Note in `--fix` output that it is best-effort, review the
     diff.
2. **Wire into `trellis-install` SKILL.** New step after the hook install (step 4/5 area):
   run `sh "$SRC/scripts/check-compliance.sh"` in report mode; if the developer invoked
   `/trellis-install --fix`, run with `--fix`. Non-blocking: report and continue. Fold the result
   into the confirm step (clean vs N violations + the `--fix` hint).
3. **Wire into `trellis-update` SKILL.** Same step and `--fix` passthrough.
4. **Test (before commit).** In the worktree:
   - Unit-style: a scratch dir with a file containing an em-dash and an en-dash -> report shows
     both with line numbers, exit 1. `--fix` -> ASCII, exit 0, re-run clean.
   - Binary skip: a file with NUL bytes containing a dash byte sequence is not reported.
   - Dogfood: run the scanner at repo root -> clean (exit 0).
5. **Commit** (Conventional Commit), push, open PR.
6. **Review** with personas whose facet this touches: engineer (shell logic), tester (observable
   behavior + the test cases), architect (new `scripts/` boundary, reuse by future hook/CI),
   security (a consumer-run script that can rewrite files). Address every major/blocker, log to
   feedback + learnings.
7. **Merge** on approval; remove the worktree.
8. **Reflect**: features (new compliance pass), architecture (the `scripts/` dir + report/fix
   contract), learnings (only if friction produced one).
9. **Release** (after merge, on main): bump the 7 manifests to the new version, tag SemVer (no
   `v`), `gh release create` with notes. The whats-new workflow rewrites the README block; verify
   it did, else update by hand.

## Verification

- `check-compliance.sh` exits non-zero with `file:line` on dashes, zero when clean.
- `--fix` remediates and a re-run is clean; binary/untracked files untouched.
- Both skills run the pass; report mode never blocks install/update.
- This repo scans clean (dogfood).
