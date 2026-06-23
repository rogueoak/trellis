# 0005 - commit-msg validation gaps

From PR #4 review (tester major + minor; engineer minor).

## Symptom

Two ways the `commit-msg` hook judged wrongly:

- A whitespace-only description passed: `feat:   ` was accepted because the pattern ended in
  `: .+`, and `.+` happily matches the trailing spaces.
- Comment stripping was hardcoded to `^#`. A repo with a non-`#` `core.commentChar` (or
  `commentChar = auto`) kept its comment lines in the message, so a valid commit was rejected
  because a comment line was read as the subject.

## Root cause

The pattern treated "any character" as "content", and the hook assumed git's default comment
char instead of asking git.

## Fix

End the pattern at `: .*[^[:space:]]` so the description must contain a real (non-space)
character. Resolve `git config core.commentChar` (falling back to `#`, and treating `auto` as
`#`) and strip that char's lines via a `case` prefix test, which is robust to regex-special
comment chars.

## Learning

A delimiter followed by `.+` still matches whitespace-only input - anchor on a non-space char
when you mean "non-empty". Hooks must honor repo config (`core.commentChar`), not hardcode
defaults. Feeds `overview/learnings.md`.
