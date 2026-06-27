# Contributing to Trellis

Thanks for helping grow the trellis. This repo is small, opinionated, and follows its own
rules - so contributing is mostly a matter of reading them once.

## Before you start

- Read the rules in [`docs/rules/`](docs/rules/): `guidelines.md` (how to write and ship) and
  `language.md` (the voice for anything public-facing).
- This repo is built under [Spectra](https://github.com/rogueoak/spectra). Read
  [`docs/spectra/protocol.md`](docs/spectra/protocol.md) and route your change the way it asks:
  a trivial fix goes straight in, a feature gets a spec in `docs/specs/` first, and a bug or a
  piece of process feedback gets a doc in `docs/feedback/`.

## Making a change

1. Branch off `main`. Multi-step work builds in a git worktree - see the protocol.
2. Keep text ASCII: never use em-dashes or en-dashes. Use a spaced hyphen ` - `, a comma, or
   two sentences instead.
3. Get tests, lint, and build green before you push. No "fix it in a follow-up."
4. Write commit messages as Conventional Commits: `type(scope): summary` (`feat`, `fix`,
   `docs`, `chore`, and so on). The shipped commit-msg hook checks this for you.
5. Open a pull request, and resolve every review comment before it merges.

## Releases

Tag releases with a Semantic Versioning number and no `v` prefix (`0.1.2`, not `v0.1.2`). The
"What's new" block in the README rewrites itself from your release notes.

## Questions

Open an issue. Small, specific, and example-driven - the same voice we write everything else in.
