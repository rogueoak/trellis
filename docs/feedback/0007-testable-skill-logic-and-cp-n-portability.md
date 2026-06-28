# 0007 - Skill-embedded shell needs a tested script, and cp -Rn is not portable

## Symptom

Spec 0006 first shipped the `/trellis-template` apply/list logic as shell **embedded in
`SKILL.md` prose**. Two problems surfaced in review and testing:

1. **No automated coverage (tester, major).** CI cannot exercise shell that lives inside a Markdown
   skill, so the apply/list/registry logic had zero tests. Concrete evidence it mattered: the first
   draft silently dropped the `touch docs/rules/.trellis-templates` that the install version had, so
   a first-run apply wrote a "No such file" to stderr - exactly the kind of regression a test
   catches and prose review nearly missed. The same draft also carried dead code (`before=$(find
   ...)`) for a skip-report it never implemented.
2. **`cp -Rn` is not portable (found while writing the test).** BSD `cp` (macOS) returns a
   non-zero exit when `-n` skips an existing file; GNU `cp` returns zero. With the apply logic now
   re-runnable, a second apply (seed targets already present) made `cp -Rn` exit non-zero, which
   under `set -e` failed the whole apply - on macOS, the platform most consumers run.

## Root cause

1. Logic that only exists as prose in a skill is unreachable by the test runner, so it rides on
   review alone. The proven parts of the codebase (`install-hooks.sh`, `check-compliance.sh`,
   `bump-version.sh`) are scripts precisely so they can be tested and cannot drift; the new logic
   broke that pattern.
2. `cp -n`'s exit status is unspecified across implementations. Relying on it for "skip if present"
   couples correctness to the platform, and a Linux-only CI never sees the BSD behavior.

## Fix

- Extracted the copy/registry logic into one shipped, tested script,
  `trellis/scripts/template.sh` (`list` / `apply` / `refresh`), and made both the `trellis-template`
  and `trellis-update` skills call it - so apply and update share one implementation that cannot
  drift, with `template.test.sh` (22 cases) wired into CI.
- Replaced `cp -Rn` with a portable per-file seed copy: for each seed file, keep and report the
  target if it already exists, else `mkdir -p` its parent and `cp -p` it. This also makes the
  promised "seed kept" report real instead of dead code.
- Added a name-charset guard (`[A-Za-z0-9_-]`) before any path use, closing the path-traversal write
  the security persona flagged.

## Learning

- When a skill needs more than a couple of lines of shell, ship it as a script the skill calls, not
  prose - only a script can be unit-tested and kept from drifting. Embedded skill shell is for glue,
  not logic.
- Do not depend on `cp -n` (or its exit status) for "copy if absent": BSD returns non-zero on skip,
  GNU returns zero. Copy per file with an explicit existence check, which is portable and yields an
  accurate skipped/written report. A Linux-only CI will not catch the BSD difference - reason about
  the consumer's platform (macOS) explicitly.
