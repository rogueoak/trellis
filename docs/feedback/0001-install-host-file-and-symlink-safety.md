# 0001 - Install host-file and symlink safety

From PR #1 review (engineer + security major, architect nit).

## Symptom

The install skill used `ln -sf AGENTS.md CLAUDE.md`, which would overwrite a consumer's real
`CLAUDE.md`/`GEMINI.md` (and follow/destroy an existing symlink). And when it created a fresh
`AGENTS.md` next to an existing real `CLAUDE.md`, the Trellis block landed only in `AGENTS.md`,
so a Claude agent reading `CLAUDE.md` never saw it.

## Root cause

The host-file handling was lifted from Spectra's prose verbatim. The "unless those files already
exist" guard lived only in the prose, not in the shell, and the command used `-f`.

## Fix

Marker-based, idempotent block insert via `awk` (replace between `trellis:start`/`end`, else
append). Symlinks are created only when `AGENTS.md` is made fresh, each guarded by `[ -e ]` with
a plain `ln -s` (never `-f`). The real-`CLAUDE.md` edge is called out in the step so the agent
reconciles it instead of silently dropping the block.

## Learning

When a skill mutates a consumer's files, the shell must enforce every promise the prose makes.
Do not inherit a sibling project's looser handling verbatim. Feeds `overview/learnings.md`.
