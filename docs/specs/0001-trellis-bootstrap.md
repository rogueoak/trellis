# 0001 - Bootstrap Trellis as an installable AI-convention framework

## Problem

rogueoak projects need one opinionated, shared set of AI-agent conventions, so every repo
behaves the same way instead of each one reinventing or drifting. Trellis is that framework:
"the structure that helps every project grow." It holds the rules agents follow plus shared
templates, and it must be adoptable (and updatable) by any repo the same way Spectra is,
without copy-pasting files.

## Outcome

- An agent can add the Trellis marketplace, install the plugin, run `/trellis-install` in any
  repo, and get a `docs/rules/` directory plus a host-file block that points agents at it.
- `/trellis-update` re-syncs an installed repo's rules to the plugin version.
- This repo ships two rules to start: `guidelines.md` (writing + code rules) and `language.md`
  (voice and tone for public-facing writing).
- A README and a logo present Trellis in the rogueoak / Spectra house style.
- Trellis dogfoods itself: `docs/rules/` in this repo is its own installed copy.

## Scope

**In**

- Root marketplace manifests: `.claude-plugin/`, `.cursor-plugin/`, `.agents/plugins/`.
- Shippable plugin dir `trellis/`: per-agent manifests (claude / codex / cursor +
  `gemini-extension.json`), `commands/trellis-install.toml` + `commands/trellis-update.toml`
  (thin wrappers), `skills/trellis-install/SKILL.md` + `skills/trellis-update/SKILL.md`,
  `rules/{guidelines,language}.md` (source of truth), `agents.md` (the host block),
  `templates/` (scaffolded, empty for now).
- `README.md` + `assets/logo.svg`.
- Dogfood install into this repo: populate `docs/rules/`, add the Trellis block to `AGENTS.md`.

**Out (later)**

- CI / token-report / `test.sh` harness (Spectra has these; defer until the structure settles).
- Actual template content (the dir ships empty for now; rules come first).
- Any review/persona machinery: that is Spectra's job. Trellis ships rules + templates only,
  and is itself developed under Spectra.

## Approach

- Mirror Spectra's layout closely, renaming `spectra` to `trellis`. Source of truth is
  `trellis/rules/`; the consumer copy is `docs/rules/`. Same split Spectra uses
  (`spectra/protocol.md` source, `docs/spectra/protocol.md` installed).
- `trellis-install`: scaffold `docs/rules/`, copy `rules/*.md` (and `templates/*` if present),
  then insert or replace a `<!-- trellis:start -->`...`<!-- trellis:end -->` block in the host
  file (`AGENTS.md` if present, else `CLAUDE.md`, else create `AGENTS.md` + symlink
  `CLAUDE.md`/`GEMINI.md`). Here `AGENTS.md` already exists (from Spectra), so the block is
  appended alongside the Spectra block.
- `trellis-update`: re-copy `rules/*.md` and replace the host block in place; leave anything
  the consumer added untouched.
- Rules content: `guidelines.md` encodes the rules given (no em/en dashes + ASCII; tests/lint/
  build green before push/merge; resolve PR comments as addressed, all resolved before merge).
  `language.md` encodes the interviewed voice: warm and human with a touch of dry wit, specific,
  enough context for a capable reader without labouring the point; address the reader as "you"
  (no first person); terse and example-driven; avoid marketing hype and buzzwords; ASCII only.
- Logo: a trellis / lattice with something growing on it, in the dark-panel + gradient style of
  the Spectra and rogueoak marks, using a green "growth" gradient. Tagline: "The structure that
  helps every project grow."

## Acceptance

- [ ] Root marketplace manifests exist for claude / cursor / agents; plugin manifests exist for
      claude / codex / cursor + `gemini-extension.json`.
- [ ] `/trellis-install`, run in a fresh repo, produces `docs/rules/{guidelines,language}.md` and
      a Trellis host block; `/trellis-update` re-syncs them.
- [ ] `trellis/rules/guidelines.md` carries the writing + code rules; `trellis/rules/language.md`
      carries the interviewed voice with concrete examples; neither uses em/en dashes.
- [ ] `README.md` mirrors the Spectra structure (logo, tagline, quick start, what lands in a
      consumer repo, repo layout, license).
- [ ] `assets/logo.svg` matches the rogueoak / Spectra visual style.
- [ ] This repo dogfoods Trellis: `docs/rules/` is populated and `AGENTS.md` has the Trellis block.
