# 0005 - Optional templates, and a plugin-release template (plan)

Source: `docs/specs/0005-plugin-release-template.md`.

## Layout to create

```
trellis/templates/README.md                         # the optional-template convention
trellis/templates/plugin-release/
  README.md                                          # adoption guide + the one CI-name knob
  owned/                                             # refreshed on update (Trellis-owned)
    scripts/bump-version.sh
    .github/workflows/release.yml
    docs/releases/README.md
  seed/                                              # copied once, never clobbered (consumer-owned)
    VERSION
    .version-manifests
```

Consumer install target (functional paths, mirrors the subtrees):
`scripts/bump-version.sh`, `.github/workflows/release.yml`, `docs/releases/README.md` (owned);
`VERSION`, `.version-manifests` (seed). Tracking: `docs/rules/.trellis-templates` (names) +
`docs/rules/.trellis-owned-<name>` (owned files).

## Steps
1. **Plan** (this) + reflect later.
2. **`bump-version.sh`** (owned, POSIX sh + python3): identical to Spectra #28's hardened script
   except the manifest list comes from `.version-manifests` (one path per line, `#` comments and
   blanks skipped) instead of a hardcoded list, and the root override env is neutral
   (`BUMP_VERSION_ROOT`). Modes: no-arg prints VERSION; `--check`; `X.Y.Z`. Carry over: surgical
   one-token substitution, validate-in-memory-then-write-VERSION-last, exactly-one-token guard,
   `if check; then` (set -e safe). Harden the semver gate to reject a multiline arg (a newline in
   the arg fails the test). Missing `.version-manifests` is a clear error.
3. **`release.yml`** (owned): `on: workflow_run: { workflows: ["CI"], types: [completed] }`.
   Job `release`: `if` success + `head_branch == 'main'`; `runs-on: ubuntu-latest`;
   `permissions: { contents: write }`; checkout pinned to the same SHA whats-new.yml uses, with
   `ref: ${{ github.event.workflow_run.head_sha }}`; step reads `v=$(cat VERSION)`, idempotent
   `gh release view` guard, `gh release create "$v" --target "$(git rev-parse HEAD)"` with
   `--notes-file docs/releases/$v.md` when present else `--generate-notes`; `GH_TOKEN` ambient.
4. **`docs/releases/README.md`** (owned): per-version notes convention (first non-heading line is
   the headline `whats-new.yml` extracts); note the generate-notes fallback caveat.
5. **`seed/VERSION`** = `0.0.0` sample; **`seed/.version-manifests`** = a commented sample listing
   the common manifest paths, for the consumer to edit.
6. **`templates/README.md`** + **`plugin-release/README.md`**: the convention (owned vs seed,
   `--template` add, auto-refresh on update) and adoption steps (set VERSION, fill
   `.version-manifests`, ensure a CI workflow named to match `release.yml`'s `workflows:` list).
7. **trellis-install SKILL.md**: a new step - if invoked with `--template <name>`, verify
   `$SRC/templates/<name>` exists, copy `owned/.` and `seed/.` to repo root (owned clobbers; seed
   via `cp -Rn`), append `<name>` to `docs/rules/.trellis-templates` (dedup), and write
   `docs/rules/.trellis-owned-<name>` (the owned file list, derived from `owned/`). Confirm.
8. **trellis-update SKILL.md**: a new step - for each name in `docs/rules/.trellis-templates`,
   re-copy `$SRC/templates/<name>/owned/.` (clobber), rewrite `.trellis-owned-<name>`, prune any
   listed owned file no longer shipped; never touch `seed/` targets. No `--template` needed.
9. **Trellis self-adoption**: root `VERSION` = `0.4.0`; `.version-manifests` listing the 4
   manifests; copy the owned script/workflow/convention to functional paths; add minimal
   `.github/workflows/ci.yml` (push + PR: run `trellis/scripts/check-compliance.test.sh`,
   `trellis/scripts/bump-version.test.sh`, and `check-compliance.sh`); run
   `scripts/bump-version.sh 0.4.0` to set all 4 manifests; confirm `--check` is clean.
10. **`trellis/scripts/bump-version.test.sh`** in the repo idiom (sandbox repos, `check`/`checkeq`):
    `--check` on a synced sandbox, semver accept/reject (incl. multiline + empty), sandbox write
    converges, **negative drift** (edit one manifest -> `--check` non-zero), **two-token guard**
    (planted second token -> non-zero), missing-manifest error. Plus a dogfood-integrity check
    that the repo's `scripts/bump-version.sh` matches the template's owned copy.
11. **Reflect**: `docs/overview/features.md` (optional templates + plugin-release), `architecture.md`
    (the owned/seed model, registry, release pipeline), `learnings.md` if a lesson arises.

## Verify
- `sh trellis/scripts/bump-version.test.sh` passes; `sh trellis/scripts/check-compliance.test.sh`
  still passes.
- `scripts/bump-version.sh --check` exits 0 on the repo; all 4 manifests + VERSION read `0.4.0`.
- Every new shell/yaml file is ASCII-only (guidelines.md); `python3 -m json.tool` parses manifests.
- `release.yml` and `ci.yml` are valid YAML; `release.yml` gates on the `ci.yml` workflow name.
- Dry-run the install/update template logic in a scratch dir to confirm copy + registry + prune.

## Review
Personas (engineer/tester/architect/security):
- **engineer** - the config-driven script, the skill copy/prune logic, release.yml shell.
- **tester** - bump-version.test.sh coverage + the install/update dry-run.
- **architect** - the optional-template model, owned/seed boundary, registry, release pipeline.
- **security** - release.yml privilege (job-scoped write, success+main gate, SHA-pinned checkout,
  ambient token, no untrusted interpolation); the script's arg/env handling.
