# 0002 - Distribute Spectra as a Trellis dependency

## Problem

A repo that adopts Trellis almost always wants Spectra too: Trellis is the conventions, Spectra
is the process, and they compose. Today that means adding two marketplaces, installing two
plugins, and running two install commands. One step should get both.

## Outcome

- Adding the Trellis marketplace and installing the `trellis` plugin **auto-installs** the
  `spectra` plugin - no second marketplace, no second install.
- `/trellis-install` scaffolds **both** into the repo in one run: Spectra's protocol, personas,
  reflection hook, and host block, plus Trellis's rules and host block.
- Updates keep both current.

## Scope

**In**

- Root marketplace manifests list two plugins: `trellis` (local `./trellis`) and `spectra`
  (external, sourced from `rogueoak/spectra`), so one `/plugin marketplace add rogueoak/trellis`
  exposes both.
- `trellis/.claude-plugin/plugin.json` declares a dependency on `spectra`; the marketplace adds
  `allowCrossMarketplaceDependenciesOn` if the dependency resolves to a separate marketplace
  name. Installing `trellis` then pulls `spectra` automatically.
- `/trellis-install` runs Spectra's scaffold (reusing the installed `spectra` plugin's files, not
  a vendored copy) and then the Trellis rules. Automatic, per the install-UX decision.
- `/trellis-update` runs Spectra's update too (refreshes the installed Spectra scaffold) and then
  its own, so one update command keeps both current.
- Cross-agent: the dependency/marketplace wiring must be **verified to actually work on Claude
  Code, OpenAI Codex, and Gemini CLI** (and Cursor), not just declared. Where an agent lacks
  dependency auto-install, document a two-step fallback for that agent specifically.

**Out**

- Vendoring Spectra's content into Trellis (rejected: duplication + version drift). Trellis
  re-lists and depends on Spectra; it does not copy it.
- Any change to Spectra itself.

## Approach

- **Mechanism: native plugin dependencies (approach A), confirmed supported.** Claude Code
  plugins support a `dependencies` array that auto-installs transitively, including across
  marketplaces with an allowlist. The Trellis marketplace re-lists Spectra (external GitHub
  source) so it is a single marketplace add; `trellis` depends on `spectra`.
- **Repo scaffold.** The plugin dependency installs the Spectra *plugin* (its commands). To also
  scaffold Spectra into the repo automatically, `/trellis-install` locates the installed Spectra
  plugin root and runs its install steps, then its own. (The non-interactive-install limitation
  does not bite us: the dependency handles the plugin layer at `/plugin install` time, and the
  scaffold layer is plain file ops the skill already performs.)
- **Coupling: track latest.** The marketplace source points at Spectra's default branch, so
  Trellis users get current Spectra without a Trellis re-release. To keep an installed repo in
  sync, `/trellis-update` also runs Spectra's update, so the repo's Spectra scaffold is refreshed
  alongside the Trellis rules in one command.
- **Validation spike first.** Before the full UX, confirm in a scratch setup that installing
  `trellis` actually auto-installs `spectra` as documented (dependency `marketplace` field
  semantics when re-listing an external plugin are the main unknown). If the spike fails, fall
  back to approach B (one marketplace, two plugins, user installs both).

## Risks / open questions

- Does the dependency resolve correctly to a Spectra entry re-listed inside the Trellis
  marketplace, or must it reference the original `spectra` marketplace via the allowlist? The
  spike answers this.
- How `/trellis-install` reliably finds the Spectra plugin root across agents (Claude exposes
  `CLAUDE_SKILL_DIR` for Trellis's own skill, not Spectra's). May need a documented
  `SPECTRA_SRC`/discovery step, or fall back to running `/spectra-install` as a second command.
- Codex/Cursor/Gemini dependency support is less certain than Claude's; fallback documented.

## Acceptance

- [ ] `/plugin marketplace add rogueoak/trellis` then `/plugin install trellis@trellis` leaves
      both `trellis` and `spectra` installed (verified in `/plugin list`).
- [ ] `/trellis-install` leaves the repo with Spectra's scaffold (`docs/spectra/`, protocol,
      personas, hook, Spectra host block) **and** Trellis's rules (`docs/rules/`, Trellis host
      block), in one run.
- [ ] `/trellis-update` refreshes both the Spectra scaffold and the Trellis rules in one run.
- [ ] Trellis tracks the latest Spectra (marketplace source on Spectra's default branch).
- [ ] The auto-install is confirmed to work on **Claude Code, OpenAI Codex, and Gemini CLI**
      (and Cursor); for any agent where it does not, a fallback is documented.
