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
- **Shipped git hooks.** `trellis/hooks/` holds dependency-free hooks (currently `commit-msg`).
  Install copies them into the *resolved* hooks dir (`git rev-parse --git-path hooks`, which is
  correct under worktrees and `core.hooksPath`). A foreign hook is displaced to `<hook>.local` and
  chained to (Trellis runs first, hands off on pass) rather than appended after - appending breaks
  when the existing hook ends in `exit 0`. Install/update warn when `core.hooksPath` is set, since
  a manager (husky/lefthook) would otherwise silently shadow the copied hook.
- **Built under Spectra.** `docs/{specs,plans,feedback,overview}` track this repo's own
  development; the two systems compose - Spectra is the process, Trellis is the conventions.
