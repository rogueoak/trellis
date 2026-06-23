# 0001 - Bootstrap Trellis (plan)

Source: spec `0001-trellis-bootstrap`. Build in worktree `.worktrees/trellis-bootstrap` on
branch `trellis-bootstrap`. Mirror Spectra's layout; rules use the source/installed split.

## Steps

1. **Plugin source of truth** `trellis/`
   - `rules/guidelines.md` - Writing + Code rules.
   - `rules/language.md` - public-writing voice (from interview), with good/bad examples.
   - `agents.md` - host block (`<!-- trellis:start -->`...`<!-- trellis:end -->`) pointing
     agents at `docs/rules/`.
   - `templates/.gitkeep` - empty, reserved.
   - Manifests: `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`,
     `.cursor-plugin/plugin.json`, `gemini-extension.json`.
   - `commands/trellis-install.toml`, `commands/trellis-update.toml` - thin wrappers that
     inject the matching `SKILL.md`.
   - `skills/trellis-install/SKILL.md`, `skills/trellis-update/SKILL.md`.

2. **Root marketplace manifests**
   - `.claude-plugin/marketplace.json`, `.cursor-plugin/marketplace.json`,
     `.agents/plugins/marketplace.json` - all point at `./trellis`.

3. **README + logo**
   - `assets/logo.svg` - lattice + growth, dark panel, green gradient, tagline.
   - `README.md` - mirror Spectra: logo, tagline, quick start (4 agents), what lands in a
     consumer repo, repo layout, license.
   - `LICENSE` - MIT, matching Spectra.

4. **Dogfood install into this repo**
   - Copy `trellis/rules/*.md` -> `docs/rules/`.
   - Append the Trellis host block to the existing `AGENTS.md` (keep the Spectra block).
   - Update `.gitignore` if needed (carry over Spectra's ignores already present).

5. **Verify** (no suite yet -> add a light structural check)
   - `trellis-install` steps run cleanly in a scratch dir and produce `docs/rules/` + block.
   - JSON manifests parse. No em/en dashes anywhere in shipped text.
   - README links resolve to real paths.

6. **Reflect** - fill `docs/overview/{project,features,architecture}.md`; add a learning only
   if the build surfaced one.

## Files touched

`trellis/**`, root `.claude-plugin/`, `.cursor-plugin/`, `.agents/plugins/`, `assets/logo.svg`,
`README.md`, `LICENSE`, `docs/rules/*`, `AGENTS.md`, `docs/overview/*`.
