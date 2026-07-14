# Features

- **Installable convention framework.** `/trellis-install` copies the shipped rules into a
  consumer repo's `docs/rules/` and wires a Trellis block into its `AGENTS.md`. `/trellis-update`
  re-syncs both to the plugin version without clobbering anything the consumer added.
- **Cross-agent distribution.** Marketplace manifests for Claude Code, Codex, Cursor, and Gemini
  all point at the single `trellis/` plugin; the install/update commands are thin wrappers over
  one shared `SKILL.md` each.
- **Shipped rules.**
  - `guidelines.md` - ASCII-only writing; tests, lint, and build green before push/merge; PR
    comments resolved before merge; Conventional Commit messages; SemVer release tags (no `v`);
    a repo baseline (every repo ships a LICENSE, README, and CONTRIBUTING) plus a standard
    README layout.
  - `conventions.md` - how code itself is written; today, versioning every API in the URL path
    (`/v1/`, `/v2/`).
  - `language.md` - the voice for public-facing writing (warm, specific, terse, example-driven,
    no hype, second person).
- **Commit-msg enforcement.** Install ships a dependency-free POSIX `commit-msg` hook that
  rejects non-Conventional-Commit subjects (allowing merges, reverts, and autosquash). It is
  copied into the repo's resolved hooks dir, displaces and chains to any existing hook, and warns
  when `core.hooksPath` would shadow it. `/trellis-update` refreshes it.
- **Compliance pass on install/update.** A shipped, dependency-free `trellis/scripts/check-compliance.sh`
  scans every tracked text file against the mechanically-checkable rules (today: `guidelines.md`'s
  em/en-dash ban) and reports each violation as `file:line`. It changes nothing by default;
  `--fix` rewrites em/en dashes to ASCII (best effort, reviewable diff). `/trellis-install` and
  `/trellis-update` run it non-blocking, passing `--fix` through when invoked as
  `/trellis-install --fix`. A developer-owned `docs/rules/.compliance-ignore` (gitignore-lite)
  skips content another tool vendors, e.g. `docs/spectra/`.
- **Optional templates.** Beyond the universal rules, Trellis ships **opt-in** templates under
  `trellis/templates/<name>/` that only some repos want. A repo lists them with `/trellis-template`
  and applies one with `/trellis-template <name>` (after `/trellis-install`); plain `/trellis-update`
  then keeps it current (registry at `docs/rules/.trellis-templates`), no re-run needed. Each
  template splits into `owned/` (Trellis refreshes these on update) and `seed/` (copied once, then
  the consumer's), so an update never clobbers consumer content. `/trellis-template` is a thin
  wrapper over a shared `SKILL.md`, like install/update. See `trellis/templates/README.md`.
- **plugin-release template.** For repos that are themselves published marketplace plugins: a root
  `VERSION` as single source of truth, `scripts/bump-version.sh` to rewrite it and every manifest
  in `.version-manifests` in lockstep (`--check` fails CI on drift, semver-only, format-preserving),
  a standalone `.github/workflows/release.yml` that tags + publishes a GitHub Release once CI
  succeeds on `main` (via `workflow_run`), a `whats-new.yml` that then refreshes the README "What's
  new" headline through an auto-merged PR (triggered by `workflow_run` of `Release`, so it survives
  the `GITHUB_TOKEN`-recursion rule), and the `docs/releases/<x.y.z>.md` notes convention. Trellis
  dogfoods it for its own seven manifests.
- **web-app template.** A web-application starting point applied with `/trellis-template web-app`:
  the fixed stack (Next.js 16 App Router, TypeScript strict, Tailwind CSS v4, the `@rogueoak/roots`
  design foundation, and the `@rogueoak/canopy` design system built on it).
  The `owned/` half is a conventions doc (`docs/templates/web-app/conventions.md`, refreshed on
  update) stating the stack and layout; the `seed/` half is a minimal starter (`package.json`,
  `tsconfig.json`, `next.config.ts`, `postcss.config.mjs`, `eslint.config.mjs`, `app/`) the repo
  owns and edits. Config is seed, so updates never clobber the consumer's app.
