# Features

- **Installable convention framework.** `/trellis-install` copies the shipped rules into a
  consumer repo's `docs/rules/` and wires a Trellis block into its `AGENTS.md`. `/trellis-update`
  re-syncs both to the plugin version without clobbering anything the consumer added.
- **Cross-agent distribution.** Marketplace manifests for Claude Code, Codex, Cursor, and Gemini
  all point at the single `trellis/` plugin; the install/update commands are thin wrappers over
  one shared `SKILL.md` each.
- **Shipped rules.**
  - `guidelines.md` - ASCII-only writing; tests, lint, and build green before push/merge; PR
    comments resolved before merge.
  - `language.md` - the voice for public-facing writing (warm, specific, terse, example-driven,
    no hype, second person).
- **Templates.** `trellis/templates/` is reserved for shared templates; empty for now.
