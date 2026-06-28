# 0006 - Fold "What's new" into the plugin-release template, fixed for automated releases

## Problem
0005 shipped the plugin-release template and Trellis self-adopted it: merging the `0.4.0` bump
auto-tagged and published the Release. But the README "What's new" headline did **not** refresh,
and dogfooding showed why:

1. A GitHub Release created by the workflow's `GITHUB_TOKEN` does **not** trigger
   `release: [published]` workflows - GitHub suppresses that to prevent recursion. So a separate
   release-triggered "What's new" job can never fire from an automated release. (Spectra's only
   ever fired because its releases were created by hand with a personal token.)
2. Trellis's existing `whats-new.yml` pushes straight to `main`, which the repo ruleset rejects
   (`push declined due to repository rule violations`), so it has been failing regardless.

So the 0005 docs overclaim "a single VERSION bump fans out to tag -> Release -> README headline."
The release half is real; the headline half is not. "What's new" also lives independently (and
differently) in Trellis and Spectra, so the release pipeline is not actually unified.

## Outcome
- The plugin-release template **owns** the full release pipeline: `bump-version.sh`,
  `release.yml`, **`whats-new.yml` + `scripts/whats-new.sh`**, and the `docs/releases` convention.
- `whats-new.yml` triggers on **`workflow_run` of the `Release` workflow** (not `release:
  published`), so it fires after an automated, `GITHUB_TOKEN`-created release. It reads the just
  released version's notes (`gh release view "$(cat VERSION)"`), regenerates the headline, and
  **lands the change through an auto-created, self-squash-merged PR** (works on a ruleset-protected
  `main`; needs the org "Allow Actions to create and approve PRs", already enabled). No direct push.
- One canonical, dependency-free `whats-new.sh` (POSIX sh + awk/sed) with a standard README marker
  pair `<!-- whats-new:start --> ... <!-- whats-new:end -->`. Derived from Spectra's tested script.
- Trellis re-adopts and cuts a release through the now-complete pipeline, so its README headline
  updates automatically; the 0005 docs are corrected to match reality.

## Scope
- **In:**
  - `trellis/templates/plugin-release/owned/.github/workflows/whats-new.yml` - `workflow_run` on
    `["Release"]`, `conclusion == 'success'`; reads the current `VERSION`'s release via `gh`,
    runs `whats-new.sh --write`, and if the README changed opens a `chore/whats-new-<tag>` branch
    and self-squash-merges it. Job-scoped `contents: write` + `pull-requests: write`; checkout
    SHA-pinned; release body reaches the script only via `env:` (no interpolation).
  - `trellis/templates/plugin-release/owned/scripts/whats-new.sh` - the canonical headline
    extractor + marker-block rewriter (`TAG`/`NAME`/`BODY` env, `--write`), markers
    `<!-- whats-new:start/end -->`, headline sanitized + length-capped.
  - `trellis/scripts/whats-new.test.sh` - port of Spectra's coverage to the Trellis idiom
    (headline = first non-heading line; name fallback; CRLF strip; marker sanitization; required
    TAG; --write rewrite + missing-markers error).
  - Update `trellis/templates/README.md` + `plugin-release/README.md`: the README needs the
    marker pair (seeded once into the consumer's README region) and a CI workflow named `CI`; the
    pipeline is now tag -> Release -> auto-merged "What's new" PR.
  - **Trellis re-adoption / dogfood:** replace the old `whats-new.yml` and `<!-- whats-new -->`
    markers with the template's; add the owned `whats-new.yml` + `scripts/whats-new.sh`; extend
    the owned-list; wire `whats-new.test.sh` into `ci.yml`; cut a release (0.4.1) so the README
    updates itself.
  - Correct 0005's `docs/overview/architecture.md` + `features.md` claims; reflect 0006.
  - A `docs/feedback/` note capturing the two gotchas, rolled into `docs/overview/learnings.md`.
- **Out:**
  - Spectra's adoption of the template - the next change, in the Spectra repo (it will replace its
    bespoke `whats-new` with this one and gain `bump-version.sh`/`release.yml`).
  - Changing the release-notes authoring convention (still `docs/releases/<v>.md`).
  - Any second template.

## Approach
- **`workflow_run` beats the token-recursion rule.** `whats-new.yml` keys on the `Release`
  workflow completing, not on the release event - so it runs even though the release was made by
  `GITHUB_TOKEN`. It then pulls the release it needs (`gh release view "$(cat VERSION)" --json
  tagName,name,body`); if that tag has no release yet (Release no-op'd because the version was
  unchanged) it exits cleanly.
- **PR, not push.** Like Spectra's, it opens `chore/whats-new-<tag>` and squash-merges its own PR
  (0 required approvals, no required checks on the ruleset), so a protected `main` stays intact.
  This is the piece Trellis's old direct-push version got wrong.
- **One script, standard markers.** The canonical `whats-new.sh` is Spectra's, with neutral
  markers (`whats-new:start/end`) so it is repo-agnostic. Both repos converge on it (Trellis here,
  Spectra on adoption), which is what "operate identically" requires.
- **Owned, so it self-heals.** Shipping `whats-new.yml` + `whats-new.sh` as owned files means a
  future fix reaches every consumer via `trellis-update` - the same reason `release.yml` is owned.
- **Least privilege + injection-safe**, mirroring `release.yml` and the existing CI: workflow
  default `contents: read`; the job adds the minimum (`contents: write` + `pull-requests: write`);
  SHA-pinned checkout; the untrusted release body is passed via `env:` and the headline is
  marker-stripped and length-capped.

## Acceptance
- [ ] `whats-new.yml` (owned) triggers on `workflow_run` of `Release` (success), reads the
      current VERSION's release, runs `whats-new.sh --write`, and self-squash-merges a PR only when
      the README changed; no-ops cleanly when the tag has no release or the block is current.
- [ ] `whats-new.sh` (owned) extracts the first non-heading line as headline (name fallback),
      sanitizes markers, caps length, rewrites only the `<!-- whats-new:start/end -->` region.
- [ ] `whats-new.test.sh` passes under `sh` and `dash`; `ci.yml` runs it.
- [ ] Trellis re-adopts: old `whats-new.yml` + `<!-- whats-new -->` markers replaced; owned-list
      and `.trellis-owned-plugin-release` updated; dogfood diff still clean.
- [ ] Releasing `0.4.1` updates the README "What's new" to the 0.4.1 headline automatically (the
      end-to-end proof).
- [ ] 0005's architecture/features claims corrected; feedback + learning recorded.
