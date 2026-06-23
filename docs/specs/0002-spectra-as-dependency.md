# 0002 - Document the Trellis + Spectra pairing

## Problem

A repo that adopts Trellis almost always wants Spectra too: Trellis is the conventions, Spectra
is the process, and they compose. We explored making Trellis auto-install Spectra as a
dependency so consumers install one thing instead of two.

## Decision

**Do not couple them. Document that consumers install both.** Only Claude Code can auto-install a
declared dependency; Codex, Gemini CLI, and Cursor cannot. Delivering an automatic, no-vendoring,
track-latest install across all four agents is not possible, and the alternatives (Claude-only
auto-install, or embedding Spectra into Trellis) each give up something that matters more. So
Trellis and Spectra stay independent, and the Trellis README explains the pairing and how to
install both.

## Cross-agent findings (the why)

- **Claude Code** - `plugin.json` supports a `dependencies` array that auto-installs (plus
  `allowCrossMarketplaceDependenciesOn` for cross-marketplace deps).
- **Codex** - no dependency field; the manifest parser silently drops unknown keys. A marketplace
  can list external sources, but each plugin installs separately.
- **Gemini CLI** - no dependency field; one extension per `gemini extensions install`.
- **Cursor** - no dependency field, and a marketplace `source` must be a relative path *inside the
  same repo*, so it cannot even reference the external `rogueoak/spectra`.

## Outcome

- The Trellis README explains the Trellis/Spectra relationship and shows how to install both.
- No vendoring, no dependency wiring, no change to the install/update skills or manifests.

## Scope

**In**

- A "Pairs with Spectra" section in the Trellis README: what each tool is, and how to install
  Spectra alongside Trellis (pointing at Spectra's own quick start for the per-agent steps).
- A learnings entry recording the cross-agent dependency finding so we do not re-research it.

**Out**

- Any plugin dependency wiring, marketplace re-listing of Spectra, or `allowCrossMarketplace...`.
- Embedding/vendoring Spectra into Trellis.
- Any change to `trellis-install` / `trellis-update`.

## Acceptance

- [ ] The README documents the Trellis + Spectra pairing and how to install both.
- [ ] No changes to manifests or skills.
- [ ] The cross-agent dependency finding is captured in `docs/overview/learnings.md`.
