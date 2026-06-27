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
- A delimiter followed by `.+` in a regex still matches whitespace-only input; when you mean
  "non-empty content", anchor on a non-space char (e.g. `: .*[^[:space:]]`). (feedback 0005)
- Git hooks must honor repo config like `core.commentChar` rather than hardcoding `#`, or they
  misfire on repos that changed it. (feedback 0005)
- Don't inline the same mutating shell in two skills; ship one script both call, so the safety
  logic cannot drift between install and update. (feedback 0004)
- A repo-wide rule (ASCII text) collides with a sibling tool's vendored docs (Spectra's
  `docs/spectra/` uses em-dashes). Don't hard-code the sibling's name into your checker - the two
  tools are independent - and don't fix files a `/spectra-update` will revert. Give the checker a
  developer-owned ignore list and skip the vendored subtree. The one place the sibling's content
  renders into a shared file (the Spectra block in `AGENTS.md`) was fixed in place and can revert;
  the durable fix is for Spectra to adopt the same rule. (spec 0004)
- A POSIX `sh` counter mutated inside a `cmd | while read` loop is lost: the pipe runs the loop in
  a subshell. To get a verdict out, act in the loop and recompute the count in a second pass (or
  use a temp file), rather than trusting a variable set inside the pipe. (spec 0004)
