# 0005 - Optional templates, and a plugin-release template

## Problem
Trellis ships *universal* conventions - rules every repo follows. But some conventions only
apply to a *kind* of repo. Every repo that is itself a published marketplace plugin (Spectra,
Trellis itself, future plugins) needs the same release machinery: a version held in one place and
mirrored into N host manifests, a way to bump them in sync, and an automated tag + GitHub
Release on merge. Today each plugin hand-rolls this. Spectra built it locally (its closed PR
#28, four-persona-reviewed); Trellis hasn't - its `0.3.0` is hardcoded across four manifests with
no source of truth, no `bump-version.sh`, and manual releases. The pattern is identical across
repos, so it should live in Trellis once, as an **opt-in** component - the first of several
project-type templates Trellis can share.

This needs two things: (1) a general notion of **optional templates** Trellis can install
selectively and keep updated, and (2) the first template, **plugin-release**.

## Outcome
- **Optional templates.** `trellis-install` gains a `--template <name>` flag to *add* an opt-in
  bundle (`trellis/templates/<name>/`); no flag installs nothing extra (fully optional). Once a
  template is installed, **`trellis-update` maintains it automatically** - it discovers installed
  templates from Trellis-owned tracking metadata and re-syncs their owned files to the current
  plugin version (refresh + prune), with **no need to re-pass `--template`**, exactly as it
  already treats rules. Base install/update behaviour is unchanged when nothing is installed.
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
  - `docs/releases/README.md` (owned) - the per-version notes convention.
  - `VERSION` (seed) - the consumer's current version, seeded once.
  - `.version-manifests` (seed) - the consumer's manifest list (one path per line), seeded with a
    sample the consumer edits.
- **Trellis dogfoods it.** Trellis adopts plugin-release for its own four manifests: a root
  `VERSION` (`0.4.0`), a `.version-manifests` listing the four, the `release.yml`, and a minimal
  `ci.yml` (push/PR) running the compliance tests so `release.yml` has a CI workflow to gate on.
  This fixes Trellis's own drift risk and cuts its next release through the new pattern.
- **Hardened from the start.** The four-persona review of Spectra's #28 surfaced five fixes; all
  are baked in here (see Approach).

## Scope
- **In:**
  - `trellis/templates/plugin-release/` - the bundle: `owned/{scripts/bump-version.sh,
    .github/workflows/release.yml,docs/releases/README.md}`, `seed/{VERSION,.version-manifests}`,
    and a `README.md` adoption guide.
  - `trellis/templates/README.md` - documents the optional-template concept and the owned/seed
    split (the convention future templates follow).
  - `trellis-install` SKILL.md: `--template <name>` adds a template - copy `owned/` + `seed/` to
    their functional paths, append `<name>` to a `docs/rules/.trellis-templates` registry, and
    write the per-template owned-list `docs/rules/.trellis-owned-<name>`.
  - `trellis-update` SKILL.md: with **no flag**, read `docs/rules/.trellis-templates`, and for
    each installed template re-copy its `owned/` files (clobber), rewrite its owned-list, and
    prune owned files Trellis no longer ships - never touching `seed/` files or consumer inputs.
    Both reuse the existing source-resolution and owned-list idioms.
  - `bump-version.sh` generalized: manifest list from `.version-manifests`, neutral root-override
    env for tests, no plugin-specific names.
  - Trellis self-adoption: root `VERSION`, `.version-manifests`, `.github/workflows/release.yml`,
    a minimal `.github/workflows/ci.yml`, and the four manifests confirmed in sync.
  - A `trellis/scripts/bump-version.test.sh` in the repo's test idiom (sandboxed, `check`/`checkeq`
    helpers) - the `--check` invariant, semver accept/reject, sandbox write/converge, a negative
    drift test, and the two-`version`-token guard.
  - Docs: spec/plan (this), `docs/overview/` (features, architecture, learnings), README "What's
    new" untouched (auto), and the template adoption README.
- **Out:**
  - Spectra adopting the template - a follow-up in the Spectra repo via `/trellis-update
    --template plugin-release` once this ships.
  - Back-filling release notes for Trellis 0.1.x-0.3.0 (already published).
  - Generalizing `whats-new.yml` itself (already in both repos; unchanged here).
  - Any second template (changelog, etc.) - the concept lands; more templates come later.

## Approach
- **Template = owned/ + seed/ + path-aware install.** The existing `cp -Rn` seeding drops flat
  files into `docs/templates/` as untracked starters; a release template instead places live
  files at specific paths and must keep the mechanism files current. So the bundle mirrors the
  target layout under `owned/` (refreshed on update, clobber) and `seed/` (copied once, no
  clobber). Install walks each subtree and copies to the repo root, preserving subpaths; the
  installed template names go in `docs/rules/.trellis-templates` and each template's owned files
  in `docs/rules/.trellis-owned-<name>`. This extends the existing owned-list idea (rules) and
  seed-once idea (templates) rather than inventing a new one.
- **Update maintains without re-asking.** Once `.trellis-templates` records a template, update
  needs no flag: it iterates that registry and re-syncs each template's owned files just like it
  re-syncs rules, so a consumer who bumps the Trellis plugin and runs `/trellis-update` gets the
  latest `bump-version.sh`/`release.yml` automatically. The `--template` flag is *add-only*.
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
  small `ci.yml` (push + PR) that runs `check-compliance` and the script tests - useful on its own
  and the gate `release.yml` waits for.

## Acceptance
- [ ] `trellis/templates/plugin-release/` exists with `owned/`, `seed/`, and a `README.md`;
      `trellis/templates/README.md` documents the optional-template convention.
- [ ] `trellis-install --template plugin-release` copies owned + seed files to their functional
      paths, appends `plugin-release` to `docs/rules/.trellis-templates`, and writes
      `docs/rules/.trellis-owned-plugin-release`; a base install with no flag installs no template.
- [ ] `trellis-update` with **no flag** reads `.trellis-templates`, refreshes each installed
      template's owned files, prunes any it no longer ships, and leaves
      `VERSION`/`.version-manifests`/`docs/releases/<v>.md` and consumer-authored content untouched.
- [ ] `bump-version.sh` reads `.version-manifests`; `X.Y.Z` rewrites `VERSION` + every listed
      manifest; `--check` exits non-zero on drift, a missing manifest, or a two-token manifest;
      semver-only (rejects `v1.2.3`, `1.2`, `1.2.3.4`, multiline, empty).
- [ ] `bump-version.test.sh` covers all of the above (incl. the negative drift and two-token
      cases) and passes; wired so `ci.yml` runs it.
- [ ] Trellis self-adopts: root `VERSION` (`0.4.0`), `.version-manifests` lists its 4 manifests,
      all 4 read `0.4.0`, `release.yml` + `ci.yml` present, `release.yml` gates on `ci.yml`.
- [ ] `release.yml`: `workflow_run` on the CI workflow, success+main guard, job-scoped
      `contents: write`, SHA-pinned checkout, idempotent `gh release view` guard, notes-file else
      generate-notes.
- [ ] `docs/overview/` (features, architecture, learnings) updated; the template README documents
      adoption + the one CI-workflow-name knob.
