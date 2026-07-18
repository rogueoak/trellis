# Contributing to Trellis

Thanks for helping grow Trellis. This repo is small, opinionated, and follows its own
rules, so contributing is mostly a matter of reading them once.

## Before you start

- Read the rules in [`docs/rules/`](docs/rules/): `guidelines.md` (how to write and ship),
  `conventions.md` (how code itself is written), and `language.md` (the voice for anything
  public-facing).
- This repo is built under [Spectra](https://github.com/rogueoak/spectra). Read
  [`docs/spectra/protocol.md`](docs/spectra/protocol.md) and route your change the way it asks:
  a trivial fix goes straight in, a feature gets a spec in `docs/specs/` first, and a bug or a
  piece of process feedback gets a doc in `docs/feedback/`.

## Making a change

To make a change, branch off of `main`, make your changes and submit a pull-request. Ensure the
changes follo the [`rules`](docs/rules/) and use Conventional Commits for your commit messages.

## Releases

Tag releases with a Semantic Versioning number and no `v` prefix (`0.1.2`, not `v0.1.2`). The
"What's new" block in the README rewrites itself from your release notes.

## Questions

Open an issue. Small, specific, and example-driven.
