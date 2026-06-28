---
name: trellis-template
description: List or apply an optional Trellis template (an opt-in bundle like plugin-release or web-app) in the current repo - copies the template's owned and seed files into place and records it so trellis-update keeps it current. Use when a repo wants to adopt a Trellis template.
---

# Apply a Trellis template

Add an optional Trellis **template** to the **current repository**, or list the ones available.
Templates are opt-in bundles under `$SRC/templates/<name>/` (see `$SRC/templates/README.md`) -
unlike `rules/`, which every Trellis repo follows. `$SRC` resolves the same way as in
`trellis-install` (`${CLAUDE_SKILL_DIR}/../..`, or `export TRELLIS_SRC=<plugin root>` on Codex /
Gemini / Cursor). Run from the repo root.

Applying requires Trellis to be installed already - the template registry lives beside the rules in
`docs/rules/`. If it is not installed, run `/trellis-install` first.

The copy/registry logic lives in one shipped, tested script (`$SRC/scripts/template.sh`, shared
with `trellis-update`) so it cannot drift; this skill just resolves `$SRC` and calls it. Invoke as
`/trellis-template` to list, or `/trellis-template <name>` to apply one.

## Steps

1. **Resolve the source**:
   ```sh
   SRC="${TRELLIS_SRC:-${CLAUDE_SKILL_DIR:?export TRELLIS_SRC=<plugin root> (see above)}/../..}"
   ```

2. **No template name given: list what is available.** Each line is a template name, a one-line
   description from its `README.md`, and `(applied)` when it is already in
   `docs/rules/.trellis-templates`:
   ```sh
   sh "$SRC/scripts/template.sh" "$SRC" list
   ```
   Then tell the developer to run `/trellis-template <name>` to apply one, and stop.

3. **A name was given: apply it.** The script validates the name (a slug; a `../`-style name is
   refused), requires an existing install, copies `owned/` (clobbering) and `seed/` (only where the
   target does not already exist), records the template in `docs/rules/.trellis-templates`, writes
   the owned-file list to `docs/rules/.trellis-owned-<name>`, and prints every seed file it kept
   because the target already existed:
   ```sh
   name=<the requested template name>             # e.g. web-app
   sh "$SRC/scripts/template.sh" "$SRC" apply "$name"
   ```
   If it exits non-zero (no such template, invalid name, or Trellis not installed), surface the
   message and run the `list` form so the developer can pick a valid one.

4. **Walk through setup.** Pass on any "seed kept (already present)" lines so the developer can
   reconcile those by hand. Then read the template's `README.md` and walk the developer through its
   setup (for `plugin-release`: set `VERSION`, fill `.version-manifests`, match the CI workflow name
   in `release.yml`; for `web-app`: `npm install`, then `npm run dev`). Stress that **owned files
   are overwritten on every update** - all customization goes in the seed files - and that
   `/trellis-update` keeps the owned files current from here, no flag needed.

5. **Confirm.** Verify the registry took, then report:
   ```sh
   grep -qxF "$name" docs/rules/.trellis-templates && [ -s "docs/rules/.trellis-owned-$name" ] \
     && echo "applied template '$name' - owned files refreshed on /trellis-update, seed files are yours." \
     || echo "template '$name' did not record cleanly - check docs/rules/.trellis-templates"
   ```
