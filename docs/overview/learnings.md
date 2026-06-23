# Learnings

- When a skill edits files in someone else's repo, make the shell enforce every promise the
  prose makes: guard destructive operations (`[ -e ]` checks, never `ln -sf`, `cp -n` for seed
  files), and verify post-conditions instead of assuming success. (feedback 0001, 0003)
- A sync/update tool needs an explicit ownership manifest - which files it owns - rather than
  matching by current filename, so it can refresh, prune renamed/removed files, and leave the
  consumer's own files untouched. (feedback 0002)
- Do not copy a sibling project's mechanism verbatim (Trellis took Spectra's host-file handling
  as-is and inherited its latent symlink bug). Re-derive its guarantees for your own context.
  (feedback 0001)
- Cross-agent plugin dependencies are not portable: only Claude Code auto-installs a declared
  `dependencies` entry. Codex, Gemini CLI, and Cursor have no dependency field (and Cursor's
  marketplace cannot even reference an external repo). Don't design a cross-agent auto-install -
  document companion installs instead, or you back yourself into vendoring. (spec 0002)
- Chaining onto an existing git hook by appending a call is unsafe: if the existing hook ends in
  `exit 0`, the appended call never runs. Displace the existing hook to `<hook>.local` and make
  yours primary, handing off to `.local` on the pass path. (spec 0003)
- A git hook manager that sets `core.hooksPath` (husky, lefthook) makes git ignore `.git/hooks/`
  entirely - it is an override, not additive. A tool that installs hooks by copying must target
  `git rev-parse --git-path hooks` and warn when `core.hooksPath` is set. (spec 0003)
