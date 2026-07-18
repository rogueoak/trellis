<p align="center">
  <img src="assets/logo.svg" alt="Trellis" width="470">
</p>

<p align="center">
  <strong>Opinionated project scaffolding</strong>
</p>

<p align="center">
  <a href="#quick-start"><img src="https://img.shields.io/badge/Claude_Code-D97757?logo=anthropic&logoColor=white" alt="Claude Code"></a>
  <a href="#quick-start"><img src="https://img.shields.io/badge/OpenAI_Codex-412991" alt="OpenAI Codex"></a>
  <a href="#quick-start"><img src="https://img.shields.io/badge/Gemini_CLI-1A73E8?logo=googlegemini&logoColor=white" alt="Gemini CLI"></a>
  <a href="#quick-start"><img src="https://img.shields.io/badge/Cursor-000000?logo=cursor&logoColor=white" alt="Cursor"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/rogueoak/trellis" alt="License: MIT"></a>
  <a href="https://github.com/rogueoak/trellis/releases/latest"><img src="https://img.shields.io/github/v/release/rogueoak/trellis?label=latest&color=2ea043" alt="Latest release"></a>
</p>

Trellis is an opinionated shared convention framework. It contains AI agent instructions for
writing and shipping code, as well as a handful of utilities for consistent enforcement.

Install it once and your agents read from the same playbook as every other repo. When the
playbook changes, pull the update in one command. The rules live in version control, in plain
Markdown, so you can read every one in a sitting. As new rules are introduced, installing the
update will apply the new conventions.

## Quick start

Install through your agent's native plugin system, then run `/trellis-install` in the repo you
want to adopt it.

**Claude Code**
```text
/plugin marketplace add rogueoak/trellis
/plugin install trellis@trellis
/reload-plugins
/trellis-install
```
`/reload-plugins` makes the newly installed commands (`/trellis-install`, `/trellis-update`,
`/trellis-template`) available in your current session.

**OpenAI Codex**
```text
codex plugin marketplace add rogueoak/trellis
```
Then install the **trellis** plugin from that marketplace and run `/trellis-install`.

**Gemini CLI**
```text
gemini extensions install https://github.com/rogueoak/trellis
```
(or `gemini extensions link .` for local development), then run `/trellis-install`.

**Cursor**

Add the `rogueoak/trellis` marketplace (in-editor marketplace panel or `/add-plugin`), then run
`/trellis-install`.

`/trellis-install` copies the rules into `docs/rules/`, points your `AGENTS.md` at them, and runs
a compliance pass that reports any existing violations of the mechanically-checkable rules (today,
the em/en-dash ban) so the repo starts in compliance, not just carrying the rules. The pass only
reports - run `/trellis-install --fix` to rewrite them, then review the diff. Later, pull updates
with `/trellis-update`. On Codex, Gemini, and Cursor, if the agent does not resolve the plugin
path on its own, the skill asks you to `export TRELLIS_SRC=<plugin root>` first.

Want an opt-in starting point on top of the rules? Run `/trellis-template` to list the available
templates and `/trellis-template <name>` to apply one - for example `/trellis-template web-app` for
a Next.js + TypeScript + Tailwind + canopy app. `/trellis-update` keeps applied templates current.

## What's new

<!-- whats-new:start -->
**1.0.2** - `conventions.md` grows from one rule to four: a nesting-depth cap, no ternaries, and design-system-token styling.
<!-- whats-new:end -->

See all releases [here](https://github.com/rogueoak/trellis/releases).

## Pairs with Spectra

Trellis is the conventions. [Spectra](https://github.com/rogueoak/spectra) is the process.
Spec-driven development with review personas. They are separate tools that compose together.

See [Spectra's quick start](https://github.com/rogueoak/spectra#quick-start) for install details.

## What lands in your repo

```
docs/
  rules/
    guidelines.md         how agents write and ship
    conventions.md        how code itself is written
    language.md           the voice for public-facing writing
    .trellis-owned        which rules Trellis manages (so updates stay clean)
AGENTS.md                 a small Trellis block points your agents at the rules
.git/hooks/commit-msg     checks your commit messages (copied in; not tracked)
```

The commit-msg hook is a dependency-free POSIX `sh` script that checks Conventional Commit format
with nothing to install (no Node, no build step). If a `commit-msg` hook already exists, Trellis
keeps it as `commit-msg.local` and chains to it rather than replacing it. If Trellis has to create
`AGENTS.md` from scratch, it also points `CLAUDE.md` and `GEMINI.md` at it so every agent reads the
same file.

## License

See [LICENSE](LICENSE).
