# 0006 - A `/trellis-template` command, and a web-app template

## Problem

Trellis has an optional-template mechanism (spec 0005): opt-in bundles under
`trellis/templates/<name>/`, split into `owned/` (Trellis refreshes) and `seed/` (yours). Today a
repo adopts one with a **`--template <name>` flag on `/trellis-install`**, and `/trellis-update`
maintains it thereafter. Two problems:

1. **The flag is confusing on install.** Templates are optional and per-repo, but bolting them onto
   the one-time base install conflates "set up Trellis" with "add this optional bundle." Adopting a
   template later, or adding a second one, means re-running *install* with a flag, which reads wrong.
2. **There is no template for the most common rogueoak project: a web application.** So every new
   web app re-picks a framework, re-wires CSS, and re-decides structure, and two rogueoak web apps
   drift on Next.js version, TypeScript strictness, styling, and where the design system plugs in.

## Outcome

- A dedicated **`/trellis-template`** command applies optional templates, fully replacing the
  `/trellis-install --template` flag (the flag is deleted, not deprecated - no backward-compat path
  for it). The command is **generic over every template** - `plugin-release` (the one that exists
  today) and `web-app` (added here) are applied the exact same way:
  - `/trellis-template` (no argument) lists the available templates, each with a one-line
    description and whether it is already applied.
  - `/trellis-template <name>` applies that template into the current repo using the existing
    `owned/`+`seed/` convention and records it so `/trellis-update` keeps it current.
  - An unknown name lists the valid templates and stops.
- `/trellis-install` no longer takes `--template`; it is purely the base install. `/trellis-update`
  is unchanged - it still auto-maintains every applied template from the registry.
- A new **web-app** template (the command's first real consumer beyond `plugin-release`) fixes the
  starting stack: **Next.js 16** (App Router), **TypeScript** (strict), **Tailwind CSS**, and
  **rogueoak/canopy** as the design system - shipped as `owned/` conventions + a `seed/` starter.

## Scope

**In**

- **New command**: `trellis/commands/trellis-template.toml` (thin wrapper) +
  `trellis/skills/trellis-template/SKILL.md` (shared skill), matching the install/update pattern.
  It carries the apply logic currently in install step 6 (copy owned clobbering + seed `cp -Rn`,
  append to `docs/rules/.trellis-templates`, write `docs/rules/.trellis-owned-<name>`), plus a
  no-argument listing mode.
- **Remove `--template` from `/trellis-install`**: delete step 6 and the flag references from
  `trellis/skills/trellis-install/SKILL.md` and its confirm step. Install becomes base-only.
- **New web-app template** `trellis/templates/web-app/`:
  - `README.md` - what it is, `/trellis-template web-app`, owned vs seed tables, post-install setup.
  - `owned/docs/templates/web-app/conventions.md` - the conventions doc (refreshed on update): the
    fixed stack, the standard layout (`app/`, `components/`, `lib/`), config choices (TS strict,
    Tailwind, App Router), how canopy plugs in, and the `docs/rules/` rules that carry over.
  - `seed/` - minimal starter (copied once): `package.json`, `tsconfig.json`, `next.config.ts`,
    `postcss.config.mjs`, `eslint.config.mjs`, `app/{layout.tsx,page.tsx,globals.css}`. Tailwind is
    v4 (CSS-first: configured via `@import "tailwindcss"` + `@theme` in `globals.css` and the
    `@tailwindcss/postcss` plugin, so there is no `tailwind.config.ts`).
- **Doc + manifest updates**: `trellis/templates/README.md` and
  `trellis/templates/plugin-release/README.md` switch from `/trellis-install --template` to
  `/trellis-template`; plugin manifests (`.claude-plugin`, `.codex-plugin`, `.cursor-plugin`,
  `gemini-extension.json`) mention the new command; root `README.md` and
  `docs/overview/{features,architecture}.md` reflect the command + the second template; the 0.4.0
  release note is corrected if that release is not yet cut, otherwise the change rides a new note.
- **Release as 1.0.0** (breaking: a shipped flag is removed). After merge, bump via the
  plugin-release pipeline (`scripts/bump-version.sh 1.0.0`, write `docs/releases/1.0.0.md`), so CI
  tags and publishes 1.0.0.
- **Dogfood**: the command applies/lists in a scratch dir; `/trellis-update` still refreshes applied
  templates; all new text passes the compliance pass.

**Out**

- Changing the `owned/`/`seed/` model, the registry files, or `/trellis-update`'s maintenance logic.
  Only the *entry point* for applying a template moves (flag to command); everything downstream is
  reused as-is.
- Having `/trellis-template` perform updates/removal. Listing + applying only; `/trellis-update`
  remains the maintainer, and un-applying stays manual for now.
- A full runnable, `npm install`-clean web-app scaffold (lockfile, CI, real components). The seed is
  a minimal known-good starting point the agent extends.
- Pinning exact patch versions or a mechanical dependency-update path; other categories (cli,
  library, service).

## Approach

- **`/trellis-template` skill.** Resolve `$SRC` exactly as install/update do
  (`${CLAUDE_SKILL_DIR}/../..`, or `TRELLIS_SRC` on other agents). Require Trellis already installed
  (`docs/rules/.trellis-owned` present) so the registry has a home; otherwise tell the developer to
  run `/trellis-install` first.
  - **No argument**: for each `$SRC/templates/<name>/` that has an `owned/` dir, print the name, the
    first line of its `README.md` as a description, and `(applied)` if it is in
    `docs/rules/.trellis-templates`. Then explain `/trellis-template <name>`.
  - **`<name>`**: validate `$SRC/templates/<name>/owned` exists (else list valid names and stop);
    `cp -Rp owned/.` (clobber) and `cp -Rn seed/.` (once) into the repo root; add `<name>` to
    `.trellis-templates` (deduped) and write `.trellis-owned-<name>` from the owned file list; read
    the template's `README.md` and walk the developer through setup; report copied vs skipped and
    stress that owned files are overwritten on update (customize seed only). This is the same logic
    that lives in install step 6 today, moved verbatim so behavior and tracking are identical.
- **Install/update edits.** Remove install step 6 and its `--template` confirm text; renumber the
  remaining steps. `/trellis-update` is untouched - it already reads `.trellis-templates` and needs
  no flag.
- **plugin-release uses the same command.** The command applies `plugin-release` identically to
  web-app (same owned/seed copy, same `.trellis-templates` / `.trellis-owned-plugin-release`
  records), so `/trellis-template plugin-release` is the one supported way to adopt it. Its
  `README.md` switches from the flag to the command. No migration path for the old flag is kept.
- **web-app conventions** state: Next.js 16 App Router + TypeScript strict; Tailwind for all
  styling; rogueoak/canopy as the component/design layer and where it wires in; the standard layout;
  and that the `docs/rules/` rules still apply. canopy is referenced as a dependency and import
  point, without inventing component APIs we cannot verify.
- **web-app seed** is the smallest set that pins the choices and runs once adapted: `package.json`
  (next 16, react, react-dom, typescript, tailwindcss, @rogueoak/canopy + `dev`/`build`/`lint`/
  `start`), strict `tsconfig.json` with the Next plugin and `@/*` alias, Tailwind + PostCSS config,
  and a minimal App Router `app/` whose `globals.css` shows the Tailwind directives plus the canopy
  import. The conventions doc says to adapt these with current patch versions.

## Decisions and trade-offs

- **A dedicated command, not an install flag.** Applying an optional, per-repo bundle is a distinct
  action from the one-time base install; folding it into install confused the two and made adopting
  a template later read as "re-install." A first-class `/trellis-template` separates "set up
  Trellis" from "add a template," mirrors the one-skill-many-wrappers pattern, and keeps install's
  job narrow. (Supersedes spec 0005's `--template` flag, which this removes.)
- **Reuse the mechanism, move only the entry point.** The `owned/`/`seed/` split, the registry, and
  `/trellis-update`'s maintenance are good and stay; only *where you trigger apply* changes. This
  keeps the change small and the tracking identical.
- **Config is seed, only the conventions doc is owned** (web-app). A web app's config is edited
  constantly, so it must be seed or `/trellis-update` would clobber the repo's own app. The
  conventions doc is the one Trellis-maintained artifact, so it is the sole `owned/` file (also
  satisfying the mechanism's requirement that every template have an `owned/` dir).
- **Doc + minimal seed, not a full scaffold.** Captures the decisions cheaply and ages gracefully;
  the agent fills the gap to a working app with current versions.

## Risks

- **A shipped convention changes.** `--template` is documented (templates README, plugin-release
  README, 0.4.0 release note). Mitigated by updating every reference in this change and, if 0.4.0 is
  already released, noting the move in the next release rather than rewriting history. Low blast
  radius: the only template so far is `plugin-release`, freshly introduced.
- **canopy specifics.** If `@rogueoak/canopy`'s package name or install source differs from the
  seed's assumption, the wiring could be slightly off. Mitigated by keeping the canopy reference
  minimal and labeling the seed a starting point. Confirm the package name/install before finalizing.
- **Version drift.** Next.js 16 and the dep set will age. Accepted: conventions name majors, the
  seed is a known-good set refreshed by hand.
- **Seed skipped on a non-empty repo.** `cp -Rn` keeps an existing `package.json`; the README and
  the apply report tell the developer to reconcile. Fresh repo is the intended path.

## Acceptance

- [ ] `/trellis-template` with no argument lists each available template with a one-line
      description and an `(applied)` marker for installed ones.
- [ ] `/trellis-template <name>` copies owned (clobber) + seed (`cp -Rn`), appends `<name>` to
      `docs/rules/.trellis-templates`, writes `docs/rules/.trellis-owned-<name>`, and reports
      copied vs skipped - identical tracking to the old flag.
- [ ] `/trellis-template <unknown>` lists the valid templates and stops; running with Trellis not
      installed points the developer to `/trellis-install`.
- [ ] `/trellis-install` no longer accepts or documents `--template`; its remaining steps are
      renumbered and still pass the confirm checks.
- [ ] `/trellis-update` (scratch) still refreshes applied templates' owned files with no flag.
- [ ] `/trellis-template plugin-release` applies it correctly (same files + registry records as the
      command produces for any template); no `--template` flag remains anywhere in shipped code or
      docs.
- [ ] `trellis/templates/web-app/` follows the convention: `README.md`, `owned/`, `seed/` mirroring
      target paths; owned conventions doc states the fixed stack and layout; seed has the minimal
      starter listed above.
- [ ] The command is a thin `.toml` over a shared `SKILL.md`, matching install/update.
- [ ] All `--template` references in shipped docs/manifests are updated to `/trellis-template`;
      README and `docs/overview/{features,architecture}.md` reflect both changes.
- [ ] No em/en dashes in any new file (compliance pass clean).
- [ ] After merge, released as 1.0.0: `VERSION` + all listed manifests at 1.0.0 (bump-version
      `--check` clean) and `docs/releases/1.0.0.md` written; CI tags and publishes the release.
