# 0002 - Document the Trellis + Spectra pairing (plan)

Source: spec `0002` (revised to the document-both decision). Single docs change, no behavior
change - so per the protocol, no persona review (self-review, merge on approval).

## Steps

1. **README** - add a "Pairs with Spectra" section: what each tool is (conventions vs process),
   how to install Spectra alongside Trellis, a pointer to Spectra's own quick start for the
   per-agent steps, and that each updates independently.
2. **Learnings** - record the cross-agent dependency finding (only Claude auto-installs; Codex /
   Gemini / Cursor do not) so it is not re-researched.
3. **Verify** - no em/en dashes in the new text; README links resolve.

## Files touched

`README.md`, `docs/overview/learnings.md`, `docs/specs/0002-spectra-as-dependency.md`,
`docs/plans/0002-spectra-pairing-docs.md`.
