---
name: trellis-update
description: Update an installed repo's Trellis rules to the plugin version - re-copies docs/rules/ and refreshes the AGENTS.md block, leaving anything you added untouched. Use after updating the trellis plugin.
---

# Update Trellis

Re-sync the Trellis-owned files in the **current repository** to the installed plugin version.
`$SRC` resolves the same way as in `trellis-install` (`${CLAUDE_SKILL_DIR}/../..`, or
`export TRELLIS_SRC=<plugin root>`). Run from the repo root.

This refreshes the shipped rules and the host block. It does **not** touch rules you authored
yourself, and it never deletes a file the plugin does not ship.

## Steps

1. **Resolve the source**:
   ```sh
   SRC="${TRELLIS_SRC:-${CLAUDE_SKILL_DIR:?export TRELLIS_SRC=<plugin root> (see above)}/../..}"
   ```

2. **Re-copy the shipped rules** (overwrite the Trellis-owned ones; leave your own additions
   alone). Refresh templates the same way if any ship:
   ```sh
   mkdir -p docs/rules
   cp "$SRC/rules/"*.md docs/rules/
   if [ -d "$SRC/templates" ] && find "$SRC/templates" -type f ! -name .gitkeep | grep -q .; then
     mkdir -p docs/templates && cp -R "$SRC/templates/." docs/templates/
   fi
   ```

3. **Refresh the host block** - in `AGENTS.md` (or `CLAUDE.md`), replace everything between
   `<!-- trellis:start -->` and `<!-- trellis:end -->` with the current `$SRC/agents.md`. If the
   markers are missing, append the block.

4. **Confirm**: tell the developer which files were refreshed.
