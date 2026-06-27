# 0004 - Bring the target repo into compliance on install

## Problem

`/trellis-install` and `/trellis-update` drop the rule text into `docs/rules/` and install the
commit-msg hook, but they never look at the repo's existing content. A repo can carry the rules
and still violate them - the rules sit beside non-compliant files. As new mechanically-checkable
rules land (today: the em/en-dash ban from `guidelines.md`), an adopting repo has no built-in way
to find or fix existing violations, so "we follow Trellis" rides on memory and luck.

## Outcome

- Install and update run a **compliance pass** over the repo's tracked text files and report every
  violation of a mechanically-checkable rule as `file:line`, with the offending text.
- By default the pass **changes nothing** (report only), preserving install's never-clobber
  stance. Run with `--fix` to remediate in place, and the developer reviews the resulting diff.
- The first (and currently only) checked rule is the em/en-dash ban: an em-dash (U+2014) or
  en-dash (U+2013) in tracked text is a violation; `--fix` rewrites them to ASCII.
- The pass is one shipped, dependency-free script, reusable later by a pre-commit hook or CI.

## Decision: report by default, fix on opt-in; mechanically-checkable rules only

- **Report by default, `--fix` to remediate.** Auto-mutating a consumer's repo on install
  contradicts the careful never-clobber design of the rest of install (templates seeded once,
  foreign hooks displaced not deleted). A surprise rewrite of someone's prose on first install is
  worse than a clear report. So report is the default and the developer opts into `--fix`; because
  the repo is git-tracked, a fix is always reviewable and reversible.
- **Mechanically-checkable rules only.** Most of `guidelines.md` cannot be applied to existing
  content (you cannot "apply" tests-pass or Conventional-Commit history to a working tree). The
  pass covers only rules that can be both *detected* and *fixed* on existing files. Today that is
  exactly the em/en-dash ban. Other rules keep their existing enforcement (the commit-msg hook,
  human review) and are out of scope here.
- **One reusable script, not inline skill steps.** Like the commit-msg hook, the check lives in a
  single POSIX `sh` script Trellis ships, so install, update, a future pre-commit hook, and CI all
  run the identical logic instead of drifting copies embedded in skill prose.
- **A `.compliance-ignore` for vendored content, not a hard-coded carve-out** (added during
  build). A repo that also runs Spectra carries Spectra's docs under `docs/spectra/`, which use
  em-dashes; this repo cannot durably fix them (a `/spectra-update` reverts the change) and the two
  tools are deliberately independent, so the scanner must not name Spectra. Instead it reads an
  optional, developer-owned `docs/rules/.compliance-ignore` (gitignore-lite) and skips matching
  paths. This repo lists `docs/spectra/` there. The em-dash the Spectra block renders into the host
  `AGENTS.md` is fixed in place (one line) so host files stay in scope; that single edit can revert
  on a `/spectra-update` (logged as a learning - Spectra should adopt the same rule).

## Scope

**In**

- `trellis/scripts/check-compliance.sh` - scans tracked text files for em/en dashes. Two modes:
  default reports `file:line: <line>` for each hit and exits non-zero if any exist; `--fix`
  rewrites the dashes to ASCII in place and reports what it changed.
- `trellis-install` SKILL: after copying rules, run the pass in report mode and surface the
  violations; when the skill is invoked as `/trellis-install --fix`, run it in fix mode instead.
- `trellis-update` SKILL: same pass, same `--fix` opt-in, so an existing repo gets newly-shipped
  checks applied when it updates.
- Dogfood: the pass runs clean on this repo (it already bans dashes via the commit e3bfa2a rule).

**Out**

- Checking rules that are not mechanically applicable to existing files (tests/lint/build green,
  Conventional-Commit history, SemVer tags, PR-comment resolution).
- A pre-commit hook or CI wired to the script - the script is designed to be reused there, but
  wiring it is a later change.
- A general per-rule plugin/checker framework. If a second checkable rule lands, extend the one
  script; a self-declaring checker system is deferred until there are enough rules to justify it.

## Approach

- **Scanner.** `check-compliance.sh [--fix]`:
  - Enumerate candidate files with `git ls-files` (so it only touches tracked content and honors
    `.gitignore`), skipping anything binary (`grep -Iq .` test) so it never corrupts non-text.
  - Match em-dash (U+2014) and en-dash (U+2013). Report mode: `grep -n` each file and print
    `file:line: text`, exit 1 if any match, exit 0 if clean. Fix mode: replace em-dash with a
    spaced hyphen ` - ` and en-dash with a plain `-`, collapse any doubled spaces the swap
    introduced, write back only changed files, and list them.
  - Best-effort fix: the em/en distinction and surrounding spacing are heuristic, so `--fix` is a
    starting point the developer reviews in the diff, not a guaranteed-perfect rewrite. The script
    says so in its output.
  - Dependency-free: POSIX `sh` + `grep`/`sed`/`perl`-free where possible; if a UTF-8-safe
    substitution needs `perl` or `iconv`, prefer the most universally present tool and degrade to
    report-only with a clear message if it is absent.
- **Skill wiring.** Both skills gain a step that runs the script. The `--fix` flag is passed
  through from how the developer invokes the command (`/trellis-install --fix`). Report mode is
  the default and is non-blocking: a dirty repo still completes install, it just ends with a list
  of what to clean up and the one-line `--fix` hint.
- **Confirm step** notes whether the repo was clean or lists the violation count.

## Risks

- **Auto-fix mangles prose.** An em-dash that should read as a comma becomes ` - `. Mitigated by
  making fix opt-in, git-tracked (reviewable diff), and clearly labeled best-effort.
- **Noisy report on first install of a dash-heavy repo.** Acceptable: a one-time list the
  developer can `--fix` or clear by hand; report mode never blocks the install.
- **Tool availability for UTF-8 fixes.** Handled by degrading to report-only with a message rather
  than failing, so install never breaks on a minimal environment.

## Acceptance

- [x] `trellis/scripts/check-compliance.sh` reports `file:line` for each em/en dash in tracked
      text files and exits non-zero; exits zero on a clean repo.
- [x] `--fix` rewrites em/en dashes to ASCII in place, reports the changed files, and leaves a
      clean repo afterward (a re-run reports nothing).
- [x] The scanner skips binary and untracked/ignored files.
- [x] The scanner skips paths in `docs/rules/.compliance-ignore` (decoupled from Spectra).
- [x] `/trellis-install` runs the pass in report mode by default and in fix mode on
      `/trellis-install --fix`; `/trellis-update` does the same.
- [x] Report mode is non-blocking: install/update still complete on a repo with violations.
- [x] The pass runs clean on this repo (dogfood, via the ignore file + the host-file fix).
- [x] No em/en dashes in any shipped text, including the new script and skill edits.
