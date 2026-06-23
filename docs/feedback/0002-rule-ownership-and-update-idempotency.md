# 0002 - Rule ownership and update idempotency

From PR #1 review (architect + tester major; security/tester minors on template clobber).

## Symptom

`trellis-update` copied shipped rules into `docs/rules/` by filename. So a consumer's
same-named rule was silently overwritten, rules Trellis renamed or dropped orphaned in every
consumer repo forever, and the skill's "won't touch rules you authored" promise was
unenforceable. Templates were copied with plain `cp -R`, clobbering consumer edits too.

## Root cause

Nothing recorded which files Trellis owns versus which the consumer authored, so update could
not reason about ownership - only about current filenames.

## Fix

Install writes `docs/rules/.trellis-owned` (the list of shipped rule files). Update refreshes the
owned files, prunes any in the list that the plugin no longer ships, and never touches files not
in the list (the consumer's own rules). Templates are seeded with `cp -Rn` so consumer edits are
never overwritten. Verified by a test: ship `a,b` then drop `b` plus add a consumer `custom.md`;
update prunes `b`, keeps `custom.md`, and rewrites the owned-list to `[a]`.

## Learning

A sync tool needs an explicit ownership manifest, not filename-matching, to refresh, prune
renames, and leave the consumer's files alone. Feeds `overview/learnings.md`.
