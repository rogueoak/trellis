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
  collect into a temp file and loop over it with `< file`, which keeps the counter), rather than
  trusting a variable set inside the pipe. (spec 0004)
- `read -d ''` (NUL-delimited, paired with `git ls-files -z`) is a bash/ksh extension, NOT POSIX;
  under `dash` it errors and the loop silently does nothing - a script that "passes" while
  checking zero files. A `#!/bin/sh` script must be tested under `dash`, and should iterate
  `git ls-files | while IFS= read -r f` (default `core.quotePath` C-quotes exotic names so they
  are skipped, not mishandled). (spec 0004)
- A shell tool that rewrites files over untrusted repo content must not write through a predictable
  temp path (`$f.tmp`) or follow symlinks: a planted `$f.tmp -> ~/.ssh/...` symlink turns an
  in-place fix into arbitrary file overwrite. Skip symlinks (`[ -L ]`), create the temp with
  `mktemp`, and guard hostile filenames with `--`/`./` so a name like `-rf` is not read as an
  option. (spec 0004)
- To share tooling that has per-repo variation, ship the mechanism verbatim and push the variation
  into a consumer-owned config file (plugin-release's `bump-version.sh` is identical everywhere;
  each repo's manifest list lives in its own `.version-manifests`). The mechanism then updates
  centrally and never needs hand-editing per repo - the same reason rules are copied, not forked.
  (spec 0005)
- An optional, updatable component needs a registry of what is installed plus a strict owned-vs-seed
  ownership split: update reads the registry and refreshes only owned files (so a clobber is always
  safe), while consumer inputs live in seed files it never touches. Without the registry, update
  cannot maintain a component the user opted into without being told again. (spec 0005)
- A portable CI-triggered release must not depend on another workflow's job names: gate it with
  `workflow_run` on the upstream workflow's *name* (success + `main`), not `needs: [job]`, so the
  same file drops into any repo. (spec 0005)
- A `GITHUB_TOKEN`-created event (a release, push, or tag made by a workflow) does NOT trigger
  further workflows - GitHub suppresses that to prevent recursion. To run work *after* an automated
  step, key on `workflow_run` of the workflow that performed it, not on the domain event it emits
  (`release: published` never fires for a token-made release). (feedback 0006)
- A workflow that writes to a ruleset-protected branch must go through a PR it opens and
  self-merges, never a direct `git push` (which the ruleset rejects) - the same constraint a human
  contributor has. (feedback 0006)
- Dogfood the whole pipeline end-to-end, not just the unit you changed: the 0005 release worked in
  isolation but the README-headline composition was broken, and only running a real release
  surfaced it. A green unit test would not have. (feedback 0006)
- When a skill needs more than a couple of lines of shell, ship it as a script the skill calls
  (like `install-hooks.sh` / `check-compliance.sh` / `bump-version.sh`), not prose embedded in
  `SKILL.md`. Only a script can be unit-tested and kept from drifting; a sibling skill that needs
  the same logic then calls the same script instead of copying it. Embedded skill shell is for glue,
  not logic. (feedback 0007)
- Do not rely on `cp -n` (or its exit status) for "copy only if absent": BSD `cp` (macOS) returns
  non-zero when it skips, GNU `cp` returns zero, so a Linux-only CI never sees the failure while
  consumers on macOS do. Copy per file with an explicit `[ -e ]` check (keep+report or `mkdir -p`
  + `cp -p`), which is portable and yields an accurate skipped/written list. This refines the
  earlier "`cp -n` for seed files" guidance: prefer the explicit per-file copy over `cp -n` for
  anything re-runnable under `set -e`. (feedback 0007)
