---
name: trellis-update
description: Update an installed repo's Trellis rules to the plugin version - refreshes the rules Trellis owns, the commit-msg hook, and the AGENTS.md block, prunes rules it no longer ships, and never touches rules you added. Use after updating the trellis plugin.
---

# Update Trellis

Re-sync the Trellis-owned files in the **current repository** to the installed plugin version.
`$SRC` resolves the same way as in `trellis-install` (`${CLAUDE_SKILL_DIR}/../..`, or
`export TRELLIS_SRC=<plugin root>` on Codex / Gemini / Cursor). Run from the repo root.

Trellis owns exactly the files listed in `docs/rules/.trellis-owned`. Update refreshes those,
removes any it no longer ships, and leaves every other file in `docs/rules/` (rules you wrote)
alone. Do not hand-edit the owned rules - your edits are overwritten here by design.

## Steps

1. **Resolve the source**:
   ```sh
   SRC="${TRELLIS_SRC:-${CLAUDE_SKILL_DIR:?export TRELLIS_SRC=<plugin root> (see above)}/../..}"
   [ -f docs/rules/.trellis-owned ] || { echo "no Trellis install found - run /trellis-install first"; exit 1; }
   ```

2. **Refresh owned rules and templates, prune orphans, rewrite the owned-lists.** Your own files,
   and any template `seed/` files, are never touched:
   ```sh
   set -- "$SRC/rules/"*.md
   [ -e "$1" ] || { echo "no rules found at $SRC/rules - is TRELLIS_SRC right?"; exit 1; }
   cp "$@" docs/rules/
   # remove rules Trellis used to ship but no longer does; your own files are not in the list
   while IFS= read -r old; do
     [ -n "$old" ] && [ ! -e "$SRC/rules/$old" ] && rm -f "docs/rules/$old"
   done < docs/rules/.trellis-owned
   ( cd "$SRC/rules" && ls *.md ) > docs/rules/.trellis-owned

   # Refresh every applied template (recorded by /trellis-template). The shared template.sh
   # re-copies each template's owned files to the current plugin version, prunes any it no longer
   # ships, and rewrites the owned-list; seed files and your content are left alone. Same script
   # /trellis-template applies with, so the copy/registry logic cannot drift.
   if [ -f docs/rules/.trellis-templates ]; then
     while IFS= read -r name; do
       [ -n "$name" ] && sh "$SRC/scripts/template.sh" "$SRC" refresh "$name"
     done < docs/rules/.trellis-templates
   fi
   ```

3. **Refresh the host block.** Replace the current Trellis block in the host file in place. Pick
   `AGENTS.md` if it exists, else `CLAUDE.md`. If neither exists, the repo is not installed - run
   `/trellis-install` instead:
   ```sh
   if [ -e AGENTS.md ]; then HOST=AGENTS.md
   elif [ -e CLAUDE.md ]; then HOST=CLAUDE.md
   else echo "no host file - run /trellis-install"; exit 1
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
   ```

4. **Refresh the commit-msg hook** with the same shipped installer install uses (idempotent: a
   Trellis hook is overwritten in place, a foreign one is displaced once and chained to):
   ```sh
   sh "$SRC/hooks/install-hooks.sh" "$SRC"
   ```

5. **Run the compliance pass** so newly-shipped checks reach existing content. The scanner checks
   every tracked text file against the mechanically-checkable rules (today: `guidelines.md`'s
   em/en-dash ban), reports by default, and changes nothing unless run with `--fix`. It is
   non-blocking. If the developer ran `/trellis-update --fix`, pass `--fix` through:
   ```sh
   sh "$SRC/scripts/check-compliance.sh" || true          # report mode (default)
   # sh "$SRC/scripts/check-compliance.sh" --fix || true   # only when invoked as /trellis-update --fix
   ```
   It honors `docs/rules/.compliance-ignore` (developer-owned) for content another tool vendors.

6. **Confirm**: tell the developer which rules were refreshed, which (if any) were pruned, that
   the commit-msg hook was refreshed, and whether the compliance pass came back clean or listed
   violations to clean up with `--fix`.
