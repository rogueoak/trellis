# 0005 - Optional templates, and a plugin-release template

> Living source of truth for the optional-template mechanism and the plugin-release template.
> Folds in the "What's new" refresh (originally drafted as a separate 0006 spec). The template's
> *entry point* is the dedicated `/trellis-template` command (spec 0006, web-app), not the
> `--template` install flag this spec first proposed; that supersession is reflected below so this
> spec matches the shipped behavior.

## Problem
Trellis ships *universal* conventions - rules every repo follows. But some conventions only
apply to a *kind* of repo. Every repo that is itself a published marketplace plugin (Spectra,
Trellis itself, future plugins) needs the same release machinery: a version held in one place and
mirrored into N host manifests, a way to bump them in sync, an automated tag + GitHub Release on
merge, and a README "What's new" headline that refreshes with each release. Today each plugin
hand-rolls this. Spectra built parts of it locally (its closed PR #28, four-persona-reviewed);
Trellis hasn't - its `0.3.0` is hardcoded across four manifests with no source of truth, no
`bump-version.sh`, and manual releases. The pattern is identical across repos, so it should live
in Trellis once, as an **opt-in** component - the first of several project-type templates Trellis
can share.

This needs two things: (1) a general notion of **optional templates** Trellis can install
selectively and keep updated, and (2) the first template, **plugin-release**, which owns the full
release pipeline end-to-end (version bump -> tag -> Release -> README "What's new").

## Outcome
- **Optional templates.** Trellis can *add* an opt-in bundle (`trellis/templates/<name>/`) into a
  repo; a base install adds nothing extra (fully optional). Applying a template is a dedicated
  action - the **`/trellis-template <name>`** command (spec 0006) - rather than a flag on install;
  the mechanism, owned/seed split, and tracking below are unchanged by that entry-point move. Once
  a template is applied, **`trellis-update` maintains it automatically** - it discovers applied
  templates from Trellis-owned tracking metadata and re-syncs their owned files to the current
  plugin version (refresh + prune), with **no need to re-apply**, exactly as it already treats
  rules. Base install/update behaviour is unchanged when nothing is applied.
  (This spec first proposed a `trellis-install --template <name>` flag; spec 0006 replaced it with
  the `/trellis-template` command and this section reflects that.)
- **A strict one-way ownership boundary.** Trellis writes and owns the template *mechanism* -
  `scripts/bump-version.sh`, `.github/workflows/release.yml`, the convention doc - plus the
  tracking metadata; these are **refreshed (clobbered) on update**, so the consumer must never
  edit them. The consumer owns their *inputs* - `VERSION`, `.version-manifests`,
  `docs/releases/<v>.md` - which live at their own functional paths and are **never** clobbered.
  No consumer-editable content ever lives inside a Trellis-owned file or path, and the consumer
  never writes into Trellis's files. The bundle encodes this split as **owned/** (refreshed) vs
  **seed/** (copied once, never touched again). The owned files of each installed template are
  tracked in `docs/rules/.trellis-owned-<name>` (Trellis-written) so update refreshes/prunes
  exactly them.
- **The plugin-release template.** Installs:
  - `scripts/bump-version.sh` (owned) - reads the consumer's manifest list from a config file,
    rewrites `VERSION` + every listed manifest via a format-preserving surgical substitution,
    `--check` enforces they agree (CI guard), semver-only.
  - `.github/workflows/release.yml` (owned) - standalone, triggered by `workflow_run` after the
    consumer's CI workflow succeeds on `main`; idempotent `gh release create` from
    `docs/releases/<v>.md` when present, else `--generate-notes`. Job-scoped `contents: write`,
    checkout pinned to a SHA.
  - `.github/workflows/whats-new.yml` (owned) - triggered by `workflow_run` of the **`Release`**
    workflow (success), not `release: published` (which a `GITHUB_TOKEN`-created release never
    fires). It reads the just-released version's notes (`gh release view "$(cat VERSION)"`),
    regenerates the README headline via `whats-new.sh --write`, and lands the change through an
    auto-created, self-squash-merged PR (works on a ruleset-protected `main`; no direct push).
    Job-scoped `contents: write` + `pull-requests: write`, SHA-pinned checkout, release body passed
    only via `env:`.
  - `scripts/whats-new.sh` (owned) - dependency-free POSIX `sh` (+ awk/sed) headline extractor and
    marker-block rewriter (`TAG`/`NAME`/`BODY` env, `--write`), rewriting only the standard
    `<!-- whats-new:start -->` ... `<!-- whats-new:end -->` region; headline sanitized and
    length-capped. Derived from Spectra's tested script so both repos converge on one canonical copy.
  - `docs/releases/README.md` (owned) - the per-version notes convention.
  - `VERSION` (seed) - the consumer's current version, seeded once.
  - `.version-manifests` (seed) - the consumer's manifest list (one path per line), seeded with a
    sample the consumer edits.
  - The consumer's README needs the `<!-- whats-new:start/end -->` marker pair (seeded once into
    its README region) and a CI workflow named `CI` for `release.yml` to gate on.
- **Trellis dogfoods it.** Trellis adopts plugin-release for its own manifests: a root `VERSION`,
  a `.version-manifests` listing them, `release.yml`, the owned `whats-new.yml` + `whats-new.sh`
  (replacing its old direct-push `whats-new.yml` and `<!-- whats-new -->` markers), and a minimal
  `ci.yml` (push/PR) running the compliance and script tests so `release.yml` has a CI workflow to
  gate on. This fixes Trellis's own drift risk and cuts its next release through the new pattern,
  including a self-refreshing README headline (proven by cutting `0.4.1`).
- **Hardened from the start.** The four-persona review of Spectra's #28 surfaced five fixes; all
  are baked in here (see Approach). The `whats-new` half was corrected after dogfooding `0.4.0`
  showed the naive design could not fire (see Approach: "What's new, fixed for automated releases").

## Scope
- **In:**
  - `trellis/templates/plugin-release/` - the bundle: `owned/{scripts/bump-version.sh,
    scripts/whats-new.sh,.github/workflows/release.yml,.github/workflows/whats-new.yml,
    docs/releases/README.md}`, `seed/{VERSION,.version-manifests}`, and a `README.md` adoption
    guide (pipeline: tag -> Release -> auto-merged "What's new" PR; the README marker pair + a CI
    workflow named `CI`).
  - `trellis/templates/README.md` - documents the optional-template concept and the owned/seed
    split (the convention future templates follow).
  - Applying: copy `owned/` + `seed/` to their functional paths, append `<name>` to a
    `docs/rules/.trellis-templates` registry, and write the per-template owned-list
    `docs/rules/.trellis-owned-<name>`. First shipped as a `trellis-install --template <name>`
    flag; spec 0006 moved this to the `/trellis-template <name>` command with identical tracking.
  - `trellis-update` SKILL.md: with **no flag**, read `docs/rules/.trellis-templates`, and for
    each applied template re-copy its `owned/` files (clobber), rewrite its owned-list, and
    prune owned files Trellis no longer ships - never touching `seed/` files or consumer inputs.
    Reuses the existing source-resolution and owned-list idioms.
  - `bump-version.sh` generalized: manifest list from `.version-manifests`, neutral root-override
    env for tests, no plugin-specific names.
  - `whats-new.yml` + `whats-new.sh` (owned): `whats-new.yml` triggers on `workflow_run` of
    `Release` (success), reads the current `VERSION`'s release, runs `whats-new.sh --write`, and
    self-squash-merges a `chore/whats-new-<tag>` PR only when the README changed. Neutral markers
    (`whats-new:start/end`) so one canonical script drops into any repo.
  - Trellis self-adoption: root `VERSION`, `.version-manifests`, `.github/workflows/release.yml`,
    `.github/workflows/whats-new.yml` (replacing the old direct-push one), the README marker swap
    (`<!-- whats-new -->` -> `<!-- whats-new:start/end -->`), a minimal `.github/workflows/ci.yml`,
    and the manifests confirmed in sync.
  - `trellis/scripts/bump-version.test.sh` and `trellis/scripts/whats-new.test.sh` in the repo's
    test idiom (sandboxed, `check`/`checkeq` helpers): for bump - the `--check` invariant, semver
    accept/reject, sandbox write/converge, a negative drift test, and the two-`version`-token
    guard; for whats-new - headline = first non-heading line, name fallback, CRLF strip, marker
    sanitization, required TAG, `--write` rewrite + missing-markers error. Both wired into `ci.yml`.
  - Docs: spec/plan (this), `docs/overview/` (features, architecture, learnings), the template
    adoption README, and a `docs/feedback/` note on the two whats-new gotchas rolled into
    `learnings.md`.
- **Out:**
  - Spectra adopting the template - a follow-up in the Spectra repo via `/trellis-template
    plugin-release` once this ships (it will replace its bespoke whats-new with this one and gain
    `bump-version.sh`/`release.yml`).
  - Back-filling release notes for Trellis 0.1.x-0.3.0 (already published).
  - Changing the release-notes authoring convention (still `docs/releases/<v>.md`).
  - Any second template (changelog, etc.) - the concept lands; more templates come later.

## Approach
- **Template = owned/ + seed/ + path-aware apply.** The existing `cp -Rn` seeding drops flat
  files into `docs/templates/` as untracked starters; a release template instead places live
  files at specific paths and must keep the mechanism files current. So the bundle mirrors the
  target layout under `owned/` (refreshed on update, clobber) and `seed/` (copied once, no
  clobber). Apply walks each subtree and copies to the repo root, preserving subpaths; the applied
  template names go in `docs/rules/.trellis-templates` and each template's owned files in
  `docs/rules/.trellis-owned-<name>`. This extends the existing owned-list idea (rules) and
  seed-once idea (templates) rather than inventing a new one. (Apply was first wired as a
  `trellis-install --template` flag; spec 0006 moved it to `/trellis-template` with the same copy
  and tracking logic.)
- **Update maintains without re-asking.** Once `.trellis-templates` records a template, update
  needs no flag: it iterates that registry and re-syncs each template's owned files just like it
  re-syncs rules, so a consumer who bumps the Trellis plugin and runs `/trellis-update` gets the
  latest `bump-version.sh`/`release.yml`/`whats-new.yml` automatically. Applying is *add-only*.
- **One-way ownership, enforced by layout.** Consumer inputs never sit inside a Trellis-owned
  file: `VERSION` and `.version-manifests` are seeded once at the repo root and then belong to
  the consumer; release notes are the consumer's `docs/releases/<v>.md`. Everything Trellis
  refreshes (the script, the workflow, the convention `README.md`, the tracking metadata) the
  consumer is told not to edit. So a clobbering refresh can never destroy consumer content.
- **Config-driven bump-version.sh.** The only repo-specific input is the manifest list, so it
  lives in a consumer-owned `.version-manifests` (one path per line) the script reads - the script
  itself ships identical to every consumer and updates in place. Everything else (the surgical
  one-token substitution, validate-in-memory-then-write, `VERSION` written last, the exactly-one-
  token guard) carries over from #28 verbatim.
- **Standalone release.yml via workflow_run.** Keying on the consumer's CI *workflow name*
  (default `CI`) instead of `needs:` on job names makes the workflow identical across repos. It
  runs only when `conclusion == 'success'` and `head_branch == 'main'`, checks out
  `workflow_run.head_sha`, and is idempotent. The one consumer-specific knob - the CI workflow
  name to wait on - is documented in the template README.
- **"What's new," fixed for automated releases.** Dogfooding the `0.4.0` bump exposed two gotchas
  the naive design missed: (1) a GitHub Release created by the workflow's `GITHUB_TOKEN` does
  **not** trigger `release: [published]` workflows (GitHub suppresses that to prevent recursion),
  so a release-event-triggered "What's new" job can never fire from an automated release; and
  (2) a `whats-new.yml` that pushes straight to `main` is rejected by a repo ruleset. So the owned
  `whats-new.yml` keys on **`workflow_run` of the `Release` workflow** completing (not the release
  event), then pulls the release it needs (`gh release view "$(cat VERSION)" --json
  tagName,name,body`; if the tag has no release yet - Release no-op'd on an unchanged version - it
  exits cleanly), and **lands the headline through an auto-created, self-squash-merged PR**
  (`chore/whats-new-<tag>`) rather than a direct push, so a ruleset-protected `main` stays intact
  (0 required approvals; the org "Allow Actions to create and approve PRs" must be enabled). One
  canonical `whats-new.sh` (Spectra's, neutral `whats-new:start/end` markers) is shared by both
  repos, and shipping both files as `owned/` means a future fix reaches every consumer via
  `trellis-update` - the same reason `release.yml` is owned. Least-privilege + injection-safe like
  `release.yml`: job-scoped `contents: write` + `pull-requests: write`, SHA-pinned checkout, and
  the untrusted release body reaches the script only via `env:` with the headline marker-stripped
  and length-capped.
- **Review fixes from #28, baked in:**
  1. Checkout pinned to a full SHA (the job carries `contents: write`).
  2. No cancel-on-push race: a standalone `workflow_run` workflow has its own run identity, so the
     concurrency-cancel problem that affected #28's shared workflow does not arise; release runs
     are not cancelled by a later push.
  3. `--generate-notes` fallback can feed a list-marker headline into "What's new" - the template
     README makes `docs/releases/<v>.md` the documented norm and notes the fallback caveat.
  4. Negative drift test + two-token guard test included in `bump-version.test.sh`.
  5. Multiline semver gate hardened (reject any argument containing a newline).
- **Minimal Trellis CI.** `release.yml` needs a CI workflow to gate on; Trellis has none. Add a
  small `ci.yml` (push + PR) that runs `check-compliance`, `bump-version.test.sh`, and
  `whats-new.test.sh` - useful on its own and the gate `release.yml` waits for.

## Acceptance
- [ ] `trellis/templates/plugin-release/` exists with `owned/`, `seed/`, and a `README.md`;
      `trellis/templates/README.md` documents the optional-template convention.
- [ ] Applying `plugin-release` (via `/trellis-template plugin-release`) copies owned + seed files
      to their functional paths, appends `plugin-release` to `docs/rules/.trellis-templates`, and
      writes `docs/rules/.trellis-owned-plugin-release`; a base install applies no template.
- [ ] `trellis-update` with **no flag** reads `.trellis-templates`, refreshes each applied
      template's owned files, prunes any it no longer ships, and leaves
      `VERSION`/`.version-manifests`/`docs/releases/<v>.md` and consumer-authored content untouched.
- [ ] `bump-version.sh` reads `.version-manifests`; `X.Y.Z` rewrites `VERSION` + every listed
      manifest; `--check` exits non-zero on drift, a missing manifest, or a two-token manifest;
      semver-only (rejects `v1.2.3`, `1.2`, `1.2.3.4`, multiline, empty).
- [ ] `bump-version.test.sh` covers all of the above (incl. the negative drift and two-token
      cases) and passes; wired so `ci.yml` runs it.
- [ ] `whats-new.yml` (owned) triggers on `workflow_run` of `Release` (success), reads the current
      VERSION's release, runs `whats-new.sh --write`, and self-squash-merges a PR only when the
      README changed; no-ops cleanly when the tag has no release or the block is current.
- [ ] `whats-new.sh` (owned) extracts the first non-heading line as headline (name fallback),
      sanitizes markers, caps length, rewrites only the `<!-- whats-new:start/end -->` region;
      `whats-new.test.sh` covers this (sh + dash) and `ci.yml` runs it.
- [ ] Trellis self-adopts: root `VERSION`, `.version-manifests` lists its manifests, all read the
      same version, `release.yml` + `whats-new.yml` + `ci.yml` present, `release.yml` gates on
      `ci.yml`; old `whats-new.yml` + `<!-- whats-new -->` markers replaced; releasing `0.4.1`
      refreshes the README "What's new" headline automatically (end-to-end proof).
- [ ] `release.yml`: `workflow_run` on the CI workflow, success+main guard, job-scoped
      `contents: write`, SHA-pinned checkout, idempotent `gh release view` guard, notes-file else
      generate-notes.
- [ ] `docs/overview/` (features, architecture, learnings) updated; the template README documents
      adoption + the one CI-workflow-name knob; a `docs/feedback/` note captures the two whats-new
      gotchas.
