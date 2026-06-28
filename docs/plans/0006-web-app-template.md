# 0006 - A `/trellis-template` command, and a web-app template (plan)

Source: `docs/specs/0006-web-app-template.md`.

## Layout to create / change

```
trellis/commands/trellis-template.toml                 # NEW thin wrapper
trellis/skills/trellis-template/SKILL.md               # NEW shared skill (list + apply)
trellis/skills/trellis-install/SKILL.md                # EDIT: remove step 6 (--template) + flag text
trellis/templates/README.md                            # EDIT: flag -> command; add web-app
trellis/templates/plugin-release/README.md             # EDIT: flag -> command
trellis/templates/web-app/                             # NEW template
  README.md
  owned/docs/templates/web-app/conventions.md
  seed/package.json
  seed/tsconfig.json
  seed/next.config.ts
  seed/postcss.config.mjs
  seed/eslint.config.mjs
  seed/app/layout.tsx
  seed/app/page.tsx
  seed/app/globals.css
```

Plus manifest/doc updates: the 7 plugin manifests' descriptions, root `README.md`,
`docs/overview/{features,architecture}.md`. Release files (`VERSION`, manifests, 1.0.0 note) are a
post-merge step.

## Steps

1. **Plan** (this) + reflect later.
2. **`trellis-template` skill** (`trellis/skills/trellis-template/SKILL.md`): resolve `$SRC` like
   install/update; require Trellis installed (`docs/rules/.trellis-owned`) else point to
   `/trellis-install`. No-arg: iterate `$SRC/templates/*/` having `owned/`, print name + first line
   of its `README.md` + `(applied)` if in `docs/rules/.trellis-templates`; then explain
   `/trellis-template <name>`. With `<name>`: validate `$SRC/templates/<name>/owned` (else list +
   exit), `cp -Rp owned/.` (clobber), `cp -Rn seed/.` (once), dedup-append to `.trellis-templates`,
   write `.trellis-owned-<name>` (`cd owned && find . -type f | sed 's#^\./##'`), read the
   template's README and walk setup, report copied vs skipped, stress owned-is-overwritten. This is
   the install step-6 logic moved verbatim.
3. **`trellis-template.toml`**: thin wrapper, `@{skills/trellis-template/SKILL.md}`, mirroring
   install/update toml.
4. **Edit `trellis-install` SKILL**: delete step 6 (Optional templates) and the `--template`
   mention in step 2's note and the confirm step; renumber remaining steps; confirm checks unchanged
   otherwise.
5. **web-app `owned/.../conventions.md`**: the fixed stack (Next.js 16 App Router, TS strict,
   Tailwind v4, `@rogueoak/canopy`), standard layout (`app/`, `components/`, `lib/`), config notes,
   how canopy wires in (dep + `import "@rogueoak/canopy/styles.css"` style reference, kept minimal),
   and that `docs/rules/` rules still apply. Mark it owned/do-not-edit.
6. **web-app `seed/`**: minimal Next 16 + TS strict + Tailwind v4 starter.
   - `package.json`: deps `next@^16`, `react`, `react-dom`, `@rogueoak/canopy`; devDeps `typescript`,
     `@types/{node,react,react-dom}`, `tailwindcss@^4`, `@tailwindcss/postcss@^4`, `eslint`,
     `eslint-config-next`; scripts `dev`/`build`/`start`/`lint`.
   - `tsconfig.json`: strict, `moduleResolution: bundler`, Next plugin, `@/*` alias.
   - `next.config.ts`: minimal typed config.
   - `postcss.config.mjs`: `@tailwindcss/postcss` plugin.
   - `eslint.config.mjs`: flat config extending `next`.
   - `app/globals.css`: `@import "tailwindcss";` + the canopy style import + a tiny `@theme`.
   - `app/layout.tsx`: imports `globals.css`, root html/body.
   - `app/page.tsx`: minimal page using a canopy element (kept conservative).
7. **web-app `README.md`**: what it is, `/trellis-template web-app`, owned vs seed tables,
   post-install setup (`npm install`, `npm run dev`), canopy note.
8. **Docs/manifests**: `templates/README.md` (flag->command, list web-app);
   `plugin-release/README.md` (flag->command); 7 manifest descriptions mention `/trellis-template`;
   root `README.md` (template/command mention + "what lands"); `docs/overview/features.md` (command
   + web-app), `architecture.md` (apply entry point moved to its own command).
9. **Dogfood test** (`/tmp` scratch, not committed): fake a `$SRC` from `trellis/`, seed a fake
   installed repo (`docs/rules/.trellis-owned`), run the apply logic for `web-app` and
   `plugin-release`, assert owned+seed copied to functional paths, `.trellis-templates` deduped,
   `.trellis-owned-<name>` correct; re-run `/trellis-update`'s template loop and assert owned
   refreshed, seed untouched. Grep the tree to assert no `--template` remains.
10. **Compliance**: `sh trellis/scripts/check-compliance.sh` clean over the new files.
11. **Reflect**: update `docs/overview/{features,architecture}.md` (and `learnings.md` only if a
    real lesson surfaces).

## Post-merge release (1.0.0, breaking)

12. After the feature PR merges: `scripts/bump-version.sh 1.0.0` (sets VERSION + all 7 manifests),
    write `docs/releases/1.0.0.md` (headline: the `/trellis-template` command + web-app template;
    breaking: `--template` flag removed), confirm `scripts/bump-version.sh --check` clean, PR,
    squash-merge; CI tags and publishes 1.0.0.

## Verify

- `sh trellis/scripts/check-compliance.sh` exits clean; every new file ASCII-only.
- JSON manifests still parse (`python3 -m json.tool`); tsconfig/package.json are valid JSON.
- Scratch dry-run: apply web-app + plugin-release -> correct files + registry; update refreshes
  owned, leaves seed; no `--template` anywhere (`grep -rn -- '--template' trellis/ docs/ README.md`).
- The command is a thin toml over the shared SKILL.md, matching install/update.

## Review

Personas (engineer/tester/architect/security), scoped to what the diff touches:
- **engineer** - the skill's shell (copy/clobber vs cp -Rn, dedup, owned-list derivation), the
  install-step removal/renumber, seed config correctness.
- **tester** - the scratch dry-run coverage (apply both templates, update idempotency, no-flag grep).
- **architect** - apply entry point as its own command vs the install flag; owned/seed boundary held
  (web-app config is seed, only conventions owned); registry reuse unchanged.
- **security** - consumer-run copy logic (no clobber of seed, paths under repo root), no new deps in
  Trellis itself; seed `package.json` pins sane majors.
