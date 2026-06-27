# Trellis templates

Templates are **optional** Trellis components that only some repos want - unlike `rules/`, which
every Trellis repo follows. Each template is a bundle under `templates/<name>/` that a repo opts
into at install:

```
/trellis-install --template <name>
```

Once installed, plain `/trellis-update` keeps the template's owned files current - no need to
re-pass the flag. Installing nothing extra is the default; base install/update ignore templates
you did not ask for.

## Anatomy of a template

A template splits its files by ownership so an update can refresh the mechanism without ever
destroying your content:

```
templates/<name>/
  README.md      # what it is, how to adopt it
  owned/         # Trellis owns these - refreshed (clobbered) on every update; do not edit
  seed/          # copied once on install, never touched again - yours to edit
```

Both subtrees mirror their target layout: a file at `owned/scripts/foo.sh` installs to
`scripts/foo.sh` in the consumer repo, `seed/VERSION` to `VERSION`, and so on.

## How install and update track a template

- Install copies `owned/` (clobbering) and `seed/` (only if absent), appends `<name>` to
  `docs/rules/.trellis-templates`, and records the template's owned files in
  `docs/rules/.trellis-owned-<name>`.
- Update reads `docs/rules/.trellis-templates` and, for each installed template, re-copies its
  `owned/` files, rewrites the owned-list, and prunes any owned file Trellis no longer ships. It
  never touches `seed/` targets or anything you authored.

The rule is one-way: **consumer-editable content never lives inside a Trellis-owned file**, so a
refresh can clobber freely. Put anything a repo customizes in `seed/`, never `owned/`.

## Templates

- **[`plugin-release/`](plugin-release/README.md)** - single-source version + automated tag and
  GitHub Release on merge, for repos that are published marketplace plugins.
