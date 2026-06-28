# Architecture

- **Source / installed split (mirrors Spectra).** The shippable source of truth is `trellis/`
  (`rules/`, `templates/`, `agents.md`, manifests, `commands/`, `skills/`). A consumer repo
  receives copies in `docs/rules/`. This repo dogfoods itself, so `docs/rules/` here is its own
  installed copy.
- **One skill, many wrappers.** Each command (`commands/*.toml`) injects the matching
  `skills/<name>/SKILL.md` at runtime, so Claude / Codex / Cursor run identical logic from one
  source of truth.
- **Host block by markers.** Install/update insert or replace a `<!-- trellis:start -->` ...
  `<!-- trellis:end -->` block in `AGENTS.md`. Markers make updates idempotent and let Trellis
  sit alongside Spectra's block in the same file.
- **Plain Markdown rules.** Rules are version-controlled Markdown, kept terse so the whole set
  reads in a sitting and costs little context when an agent loads it.
- **Ownership manifest.** Install records the files Trellis ships in `docs/rules/.trellis-owned`.
  Update refreshes and prunes only those, so a consumer's own rules (and renamed/removed shipped
  rules) are handled correctly instead of matched by filename alone.
- **Shipped git hooks.** `trellis/hooks/` holds dependency-free hooks (currently `commit-msg`)
  plus `install-hooks.sh`, the single installer both `trellis-install` and `trellis-update` call
  so the copy/displace logic lives in one place and cannot drift. It copies hooks into the
  *resolved* hooks dir (`git rev-parse --git-path hooks`, correct under worktrees and submodules).
  That path does **not** honor `core.hooksPath`, so the installer warns when it is set - a manager
  (husky/lefthook) would otherwise silently shadow the copied hook. A foreign hook is displaced to
  `<hook>.local` and chained to (Trellis runs first, hands off on pass) rather than appended after,
  which would break when the existing hook ends in `exit 0`; if the `.local` slot is taken the
  installer refuses rather than destroy either hook. Trellis owns a hook by its `# Trellis <name>
  hook:` marker and refreshes marked hooks, but does **not** yet prune a hook it stops shipping
  (only one hook exists today; revisit with a hooks manifest if that grows). Spectra's `pre-commit`
  install still appends-after-`exit 0`; the two are safe together only because they manage
  different hook types.
- **Compliance scanner.** `trellis/scripts/check-compliance.sh` is a single POSIX `sh` script both
  skills call (same one-script-no-drift discipline as `install-hooks.sh`), with `check-compliance.test.sh`
  covering the contract under `dash`. It enumerates tracked text via `git ls-files` (newline, not
  `-z`: POSIX `read` has no `-d`, so the NUL form is not dash-portable), skips symlinks and binary
  files (`grep -I`) and paths in the developer-owned `docs/rules/.compliance-ignore`, then reports
  em/en dashes by default or rewrites them under `--fix` (writing via `mktemp` + `mv` so a planted
  symlink or crashed write cannot clobber or leak a file). The report/`--fix` split keeps install's
  never-clobber stance: detection never mutates, remediation is opt-in and reviewable. The ignore
  file (not a hard-coded path) keeps Trellis decoupled from Spectra while still letting a repo skip
  another tool's vendored docs. Reuse by a consumer's own pre-commit/CI is deferred and will need a
  copy-into-repo step like `install-hooks.sh` has - today the script only ships in the plugin, so
  only this repo (where `trellis/` is committed) can invoke it directly.
- **Optional templates.** `trellis/templates/<name>/` bundles are opt-in, unlike `rules/`. Each
  splits into `owned/` (the mechanism Trellis maintains) and `seed/` (the consumer's inputs),
  both mirroring their target paths. Applying is its **own command**, `/trellis-template <name>`,
  not a flag on install - applying an opt-in, per-repo bundle is a distinct action from the one-time
  base install, and folding it into install conflated the two. The command merges `owned/` (clobber)
  and `seed/` (`cp -Rn`) into the repo, records the name in `docs/rules/.trellis-templates`, and
  lists the owned files in `docs/rules/.trellis-owned-<name>`; with no argument it lists the
  available templates and which are applied. Update needs no flag: it walks that registry and
  re-syncs each template's owned files exactly as it re-syncs rules (refresh + prune), never
  touching `seed/` targets. The boundary is one-way - no consumer-editable content lives in an owned
  file - so a clobbering refresh is always safe. Reuses the `.trellis-owned` ownership-manifest idea
  rather than inventing a parallel one.
- **plugin-release pipeline.** The first template. Repo-specific variation (the manifest list)
  lives in a consumer-owned `.version-manifests`, so the owned `bump-version.sh` ships identical
  everywhere and updates centrally. `release.yml` is standalone and triggered by `workflow_run` on
  the consumer's `CI` workflow (not `needs:` on job names), so it is portable; it is the only job
  with `contents: write` (job-scoped), gated to CI-success on `main`, SHA-pinned checkout,
  idempotent via `gh release view`. The owned `whats-new.yml` closes the loop: it triggers on
  `workflow_run` of `Release` (not `release: published`, which a `GITHUB_TOKEN`-created release
  never fires), reads that version's notes, and lands the README headline through an auto-merged
  PR (a protected `main` forbids the direct push the old version used). So a single `VERSION` bump
  merged to `main` fans out to tag -> Release -> README "What's new", entirely owned and updatable.
  Trellis self-adopts: a `CI` workflow runs the test suites + `bump-version.sh --check` + a dogfood
  diff (installed copies must equal the template source), and `release.yml` gates on it.
- **Built under Spectra.** `docs/{specs,plans,feedback,overview}` track this repo's own
  development; the two systems compose - Spectra is the process, Trellis is the conventions.
