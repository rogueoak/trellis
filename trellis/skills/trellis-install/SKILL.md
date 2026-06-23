---
name: trellis-install
description: Install rogueoak's Trellis AI-agent conventions into the current repo - copies the shared rules into docs/rules/ and wires up AGENTS.md. Use when a repo wants to adopt Trellis.
---

# Install Trellis

Set up the Trellis conventions in the **current repository**. `$SRC` is this plugin's root - the
directory holding `rules/`, `templates/`, and `agents.md` (the parent of this skill's `skills/`
dir). Claude Code resolves it automatically (`${CLAUDE_SKILL_DIR}/../..`); on any other agent
(Codex, Gemini, Cursor) `export TRELLIS_SRC=<plugin root>` first. Run from the repo root.

If a previous install exists, prefer running `trellis-update` instead - it re-syncs cleanly.

## Steps

1. **Resolve the source and scaffold**:
   ```sh
   SRC="${TRELLIS_SRC:-${CLAUDE_SKILL_DIR:?export TRELLIS_SRC=<plugin root> (see above)}/../..}"
   mkdir -p docs/rules
   ```

2. **Copy the rules and record what Trellis owns.** The owned-list (`docs/rules/.trellis-owned`)
   lets `trellis-update` refresh and prune only Trellis's files, never your own. Templates are
   seeded once and never clobbered:
   ```sh
   set -- "$SRC/rules/"*.md
   [ -e "$1" ] || { echo "no rules found at $SRC/rules - is TRELLIS_SRC right?"; exit 1; }
   cp "$@" docs/rules/
   ( cd "$SRC/rules" && ls *.md ) > docs/rules/.trellis-owned
   if [ -d "$SRC/templates" ] && find "$SRC/templates" -type f ! -name .gitkeep | grep -q .; then
     mkdir -p docs/templates && cp -Rn "$SRC/templates/." docs/templates/
   fi
   ```
   If a file you wrote yourself shares a name with a shipped rule, it will be overwritten - tell
   the developer rather than silently clobbering it.

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

4. **Confirm.** Verify the install actually took, then report:
   ```sh
   ok=1
   while IFS= read -r f; do [ -s "docs/rules/$f" ] || { echo "missing/empty docs/rules/$f"; ok=0; }; done < docs/rules/.trellis-owned
   grep -ql '<!-- trellis:start -->' AGENTS.md CLAUDE.md 2>/dev/null || { echo "no host file carries the Trellis block"; ok=0; }
   [ "$ok" = 1 ] && echo "Trellis installed - rules in docs/rules/, block wired into the host file."
   ```
   Tell the developer every change from here follows the rules in `docs/rules/`, and that updates
   come later with `/trellis-update`.
