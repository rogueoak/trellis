# Architecture

- **Source / installed split (mirrors Spectra).** The shippable source of truth is `trellis/`
  (`rules/`, `templates/`, `agents.md`, manifests, `commands/`, `skills/`). A consumer repo
  receives copies in `docs/rules/`. This repo dogfoods itself, so `docs/rules/` here is its own
  installed copy.
- **One skill, many wrappers.** Each command (`commands/*.toml`) injects the matching
  `skills/<name>/SKILL.md` at runtime, so Claude / Codex / Cursor run identical logic from one
  source of truth.
- **Host block by markers.** Install/update insert or replace a `<!-- trellis:start -->` ...
  `<!-- trellis:end -->` block in `AGENTS.md`. Markers make updates idempotent and let Trellis
  sit alongside Spectra's block in the same file.
- **Plain Markdown rules.** Rules are version-controlled Markdown, kept terse so the whole set
  reads in a sitting and costs little context when an agent loads it.
- **Ownership manifest.** Install records the files Trellis ships in `docs/rules/.trellis-owned`.
  Update refreshes and prunes only those, so a consumer's own rules (and renamed/removed shipped
  rules) are handled correctly instead of matched by filename alone.
- **Built under Spectra.** `docs/{specs,plans,feedback,overview}` track this repo's own
  development; the two systems compose - Spectra is the process, Trellis is the conventions.
