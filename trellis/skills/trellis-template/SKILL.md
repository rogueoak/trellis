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

The repo must already have Trellis installed - the template registry lives beside the rules in
`docs/rules/`. If it is not installed, run `/trellis-install` first.

Invoke as `/trellis-template` to list, or `/trellis-template <name>` to apply one.

## Steps

1. **Resolve the source and require an install**:
   ```sh
   SRC="${TRELLIS_SRC:-${CLAUDE_SKILL_DIR:?export TRELLIS_SRC=<plugin root> (see above)}/../..}"
   [ -f docs/rules/.trellis-owned ] || { echo "no Trellis install found - run /trellis-install first"; exit 1; }
   [ -d "$SRC/templates" ] || { echo "no templates found at $SRC/templates - is TRELLIS_SRC right?"; exit 1; }
   ```

2. **No template name given: list what is available.** For every template (a `templates/<name>/`
   with an `owned/` dir), print its name, the first line of its `README.md` as a one-line
   description, and `(applied)` when it is already recorded in `docs/rules/.trellis-templates`:
   ```sh
   touch docs/rules/.trellis-templates
   for tdir in "$SRC/templates"/*/; do
     [ -d "$tdir/owned" ] || continue
     name=$(basename "$tdir")
     desc=$(sed -n '1s/^#* *//p' "$tdir/README.md" 2>/dev/null)
     if grep -qxF "$name" docs/rules/.trellis-templates; then mark=" (applied)"; else mark=""; fi
     printf '%s%s - %s\n' "$name" "$mark" "$desc"
   done
   ```
   Then tell the developer to run `/trellis-template <name>` to apply one, and stop.

3. **A name was given: validate it.** A template must exist and have an `owned/` dir; otherwise
   list the valid names (step 2) and stop:
   ```sh
   name=<the requested template name>             # e.g. web-app
   tdir="$SRC/templates/$name"
   [ -d "$tdir/owned" ] || { echo "no such template: $name - run /trellis-template to list the available ones"; exit 1; }
   ```

4. **Apply the template.** A template splits into `owned/` (Trellis refreshes these on every update
   - never hand-edit them) and `seed/` (copied once, then yours); both mirror their target paths,
   so applying just merges them into the repo root - `owned` clobbering, `seed` only if absent.
   Record the install so `trellis-update` maintains it with no flag:
   ```sh
   before=$(find . -type f 2>/dev/null)            # to report what seed actually added
   cp -Rp "$tdir/owned/." .                        # owned -> functional paths (refresh/clobber)
   [ -d "$tdir/seed" ] && cp -Rn "$tdir/seed/." .  # seed -> once, never clobber existing
   grep -qxF "$name" docs/rules/.trellis-templates || echo "$name" >> docs/rules/.trellis-templates
   ( cd "$tdir/owned" && find . -type f | sed 's#^\./##' ) > "docs/rules/.trellis-owned-$name"
   ```
   A `seed` file whose target already exists is skipped (never clobbered); tell the developer which
   seed files were skipped so they can reconcile by hand, and which owned/seed files were written.

5. **Walk through setup.** Read the template's `README.md` and walk the developer through its setup
   (for `plugin-release`: set `VERSION`, fill `.version-manifests`, match the CI workflow name in
   `release.yml`; for `web-app`: `npm install`, then `npm run dev`). Stress that **owned files are
   overwritten on every update** - all customization goes in the seed files - and that
   `/trellis-update` keeps the owned files current from here, no flag needed.

6. **Confirm.** Verify the registry took, then report:
   ```sh
   grep -qxF "$name" docs/rules/.trellis-templates && [ -s "docs/rules/.trellis-owned-$name" ] \
     && echo "applied template '$name' - owned files refreshed on /trellis-update, seed files are yours." \
     || echo "template '$name' did not record cleanly - check docs/rules/.trellis-templates"
   ```
