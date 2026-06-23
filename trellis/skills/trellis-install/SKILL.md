---
name: trellis-install
description: Install rogueoak's Trellis AI-agent conventions into the current repo - copies the shared rules into docs/rules/ and wires up AGENTS.md. Use when a repo wants to adopt Trellis.
---

# Install Trellis

Set up the Trellis conventions in the **current repository**. `$SRC` is this plugin's root - the
directory holding `rules/`, `templates/`, and `agents.md` (the parent of this skill's `skills/`
dir). Claude Code resolves it automatically (`${CLAUDE_SKILL_DIR}/../..`); on any other agent,
`export TRELLIS_SRC=<plugin root>` before running the steps. Run from the repo root.

If a previous install exists, prefer running `trellis-update` instead - it re-syncs without
clobbering anything you have added.

## Steps

1. **Scaffold the rules dir**:
   ```sh
   SRC="${TRELLIS_SRC:-${CLAUDE_SKILL_DIR:?export TRELLIS_SRC=<plugin root> (see above)}/../..}"
   mkdir -p docs/rules
   ```

2. **Copy the rules** (full copies - the consumer has no `$SRC` after install). If the plugin
   ships any templates, copy those too:
   ```sh
   cp "$SRC/rules/"*.md docs/rules/
   if [ -d "$SRC/templates" ] && find "$SRC/templates" -type f ! -name .gitkeep | grep -q .; then
     mkdir -p docs/templates && cp -R "$SRC/templates/." docs/templates/
   fi
   ```

3. **Wire up the host file** - pick `AGENTS.md` if present, else `CLAUDE.md` if present, else
   create `AGENTS.md`. Insert the block from `$SRC/agents.md`:
   - If the file already contains `<!-- trellis:start -->` ... `<!-- trellis:end -->`, replace
     everything between (and including) the markers with `$SRC/agents.md`.
   - Otherwise append `$SRC/agents.md` to the end. (If the repo already uses Spectra, the
     Trellis block sits alongside the Spectra block - both are fine together.)
   - If you created `AGENTS.md`, also symlink `CLAUDE.md` and `GEMINI.md` -> `AGENTS.md`
     (`ln -sf AGENTS.md CLAUDE.md`) unless those files already exist. Codex and Cursor read
     `AGENTS.md` natively.

4. **Confirm**: list `docs/rules/` and tell the developer Trellis is installed - every change
   from here follows the rules in `docs/rules/`. Pull updates later with `/trellis-update`.
