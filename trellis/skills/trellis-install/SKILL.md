---
name: trellis-install
description: Install rogueoak's Trellis AI-agent conventions into the current repo - copies the shared rules into docs/rules/, installs the commit-msg hook, and wires up AGENTS.md. Use when a repo wants to adopt Trellis.
---

# Install Trellis

Set up the Trellis conventions in the **current repository**. `$SRC` is this plugin's root - the
directory holding `rules/`, `templates/`, `hooks/`, `scripts/`, and `agents.md` (the parent of
this skill's `skills/` dir). Claude Code resolves it automatically (`${CLAUDE_SKILL_DIR}/../..`); on any other agent
(Codex, Gemini, Cursor) `export TRELLIS_SRC=<plugin root>` first. Run from the repo root.

If a previous install exists, prefer running `trellis-update` instead - it re-syncs cleanly.

## Steps

1. **Resolve the source and scaffold**:
   ```sh
   SRC="${TRELLIS_SRC:-${CLAUDE_SKILL_DIR:?export TRELLIS_SRC=<plugin root> (see above)}/../..}"
   mkdir -p docs/rules
   ```

2. **Copy the rules and record what Trellis owns.** The owned-list (`docs/rules/.trellis-owned`)
   lets `trellis-update` refresh and prune only Trellis's files, never your own:
   ```sh
   set -- "$SRC/rules/"*.md
   [ -e "$1" ] || { echo "no rules found at $SRC/rules - is TRELLIS_SRC right?"; exit 1; }
   cp "$@" docs/rules/
   ( cd "$SRC/rules" && ls *.md ) > docs/rules/.trellis-owned
   ```
   If a file you wrote yourself shares a name with a shipped rule, it will be overwritten - tell
   the developer rather than silently clobbering it. (Optional **templates** are opt-in and
   handled in step 6, not seeded here.)

3. **Wire up the host file.** Pick the primary host file: `AGENTS.md` if it exists, else
   `CLAUDE.md` if it exists, else create `AGENTS.md`. Insert or replace the Trellis block (the
   marker pair makes this idempotent and lets it sit beside a Spectra block). Only when you had
   to create `AGENTS.md` fresh, point `CLAUDE.md`/`GEMINI.md` at it - never overwriting an
   existing file or symlink:
   ```sh
   if [ -e AGENTS.md ]; then HOST=AGENTS.md
   elif [ -e CLAUDE.md ]; then HOST=CLAUDE.md
   else HOST=AGENTS.md; CREATED=1; : > AGENTS.md
   fi

   if grep -q '<!-- trellis:start -->' "$HOST"; then
     awk '
       FNR==NR { blk = blk $0 ORS; next }
       /<!-- trellis:start -->/ { printf "%s", blk; skip=1; next }
       skip && /<!-- trellis:end -->/ { skip=0; next }
       !skip { print }
     ' "$SRC/agents.md" "$HOST" > "$HOST.tmp" && mv "$HOST.tmp" "$HOST"
   else
     printf '\n' >> "$HOST"; cat "$SRC/agents.md" >> "$HOST"
   fi

   if [ -n "${CREATED:-}" ]; then
     for a in CLAUDE.md GEMINI.md; do [ -e "$a" ] || ln -s AGENTS.md "$a"; done
   fi
   ```
   If `AGENTS.md` is created fresh while a *real* `CLAUDE.md` already exists, that `CLAUDE.md` is
   left untouched (so it would miss the block) - in that case also insert the block into it, or
   tell the developer to consolidate. Codex and Cursor read `AGENTS.md` natively.

4. **Install the commit-msg hook** so commits are checked for Conventional Commit format. Run the
   shipped installer - one script (shared by install and update) that copies Trellis's hooks into
   the repo's *resolved* hooks dir, displaces any foreign `commit-msg` hook to `commit-msg.local`
   (Trellis becomes primary and chains to `.local` on pass, never clobbering it), and warns if a
   hook manager has redirected `core.hooksPath`:
   ```sh
   sh "$SRC/hooks/install-hooks.sh" "$SRC"
   ```
   Pass on to the developer anything the installer reports (a displaced hook, or a set
   `core.hooksPath`).

5. **Run the compliance pass** so the repo starts in compliance, not just carrying the rules.
   The shipped scanner checks every tracked text file against the mechanically-checkable rules
   (today: `guidelines.md`'s em/en-dash ban). It **reports by default and changes nothing**; the
   developer opts into rewriting with `--fix`. It is non-blocking - a repo with violations still
   finishes installing. If the developer ran `/trellis-install --fix`, pass `--fix` through:
   ```sh
   sh "$SRC/scripts/check-compliance.sh" || true          # report mode (default)
   # sh "$SRC/scripts/check-compliance.sh" --fix || true   # only when invoked as /trellis-install --fix
   ```
   The scanner skips paths listed in `docs/rules/.compliance-ignore` (developer-owned,
   gitignore-lite), for content another tool vendors - e.g. add `docs/spectra/` when Spectra is
   installed. Surface whatever the scanner reports, and when it is dirty, point the developer at
   `--fix`.

6. **Optional templates (only when asked).** A template is an opt-in bundle under
   `$SRC/templates/<name>/` (see `$SRC/templates/README.md`). **Skip this step entirely unless the
   developer ran `/trellis-install --template <name>`.** A template splits into `owned/` (Trellis
   refreshes these on every update - never hand-edit them) and `seed/` (copied once, then yours);
   both mirror their target paths, so install just merges them into the repo root - `owned`
   clobbering, `seed` only if absent. Record the install so `trellis-update` maintains it without
   the flag:
   ```sh
   name=<the requested template name>            # e.g. plugin-release
   tdir="$SRC/templates/$name"
   [ -d "$tdir/owned" ] || { echo "no such template: $name (looked in $tdir)"; exit 1; }
   cp -Rp "$tdir/owned/." .                       # owned -> functional paths (refresh/clobber)
   [ -d "$tdir/seed" ] && cp -Rn "$tdir/seed/." . # seed -> once, never clobber existing
   touch docs/rules/.trellis-templates
   grep -qxF "$name" docs/rules/.trellis-templates || echo "$name" >> docs/rules/.trellis-templates
   ( cd "$tdir/owned" && find . -type f | sed 's#^\./##' ) > "docs/rules/.trellis-owned-$name"
   ```
   Then read the template's `README.md` and walk the developer through its setup (for
   `plugin-release`: set `VERSION`, fill `.version-manifests`, match the CI workflow name in
   `release.yml`). Stress that **owned files are overwritten on every update** - all customization
   goes in the seed files.

7. **Confirm.** Verify the install actually took, then report:
   ```sh
   ok=1
   while IFS= read -r f; do [ -s "docs/rules/$f" ] || { echo "missing/empty docs/rules/$f"; ok=0; }; done < docs/rules/.trellis-owned
   grep -ql '<!-- trellis:start -->' AGENTS.md CLAUDE.md 2>/dev/null || { echo "no host file carries the Trellis block"; ok=0; }
   HOOKS="$(git rev-parse --git-path hooks)"; grep -ql 'Trellis commit-msg hook' "$HOOKS/commit-msg" 2>/dev/null || { echo "commit-msg hook not installed"; ok=0; }
   [ "$ok" = 1 ] && echo "Trellis installed - rules in docs/rules/, commit-msg hook active, block wired into the host file."
   ```
   Tell the developer every change from here follows the rules in `docs/rules/`, that the
   compliance pass flagged either a clean repo or a list to clean up (with `--fix`), any template
   they added and its setup, and that updates come later with `/trellis-update`.
