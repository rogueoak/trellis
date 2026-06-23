# 0004 - Hook install: dedup and safety

From PR #4 review (architect major; security + engineer minors).

## Symptom

The commit-msg hook install logic was inlined in both `trellis-install` and `trellis-update`
(would drift), and had three handling holes: `cp`/`chmod` followed a planted symlink in
`.git/hooks` (write-through to an arbitrary target); the "is this our hook" gate matched the
marker substring anywhere in the file; and when `commit-msg.local` was already occupied, a
foreign `commit-msg` hook could be overwritten and lost.

## Root cause

Two copies of the same mutating shell, and a copy step that trusted whatever was already at the
destination (symlink, look-alike, or an occupied aside slot).

## Fix

One shipped installer, `trellis/hooks/install-hooks.sh`, called by both skills. It: checks an
exact first-line marker (`^# Trellis <name> hook:`); displaces a foreign hook to `<name>.local`
only when that slot is free, and **refuses** (warns, installs nothing) rather than destroy a hook
when it is taken; `rm -f`s the destination before `cp` so a symlink is broken, not written
through; and chmods only the copied file, never `.local`. The ownership question (Trellis does not
yet prune a hook it stops shipping) is documented as a deliberate limitation while only one hook
ships.

## Learning

Don't inline the same mutating shell in two skills; ship one script both call. A copy-into
step must not trust the destination - break symlinks and never clobber a file it did not write.
Feeds `overview/learnings.md`.
