# plugin-release template

Single-source plugin versioning + an automated tag and GitHub Release on merge. For repos that
are themselves published marketplace plugins (one version string duplicated across several host
manifests).

Install with:

```
/trellis-install --template plugin-release
```

After that, plain `/trellis-update` keeps the owned files current - you never re-pass the flag.

## What it installs

Owned by Trellis (refreshed on update - do not edit):

| File | Role |
|---|---|
| `scripts/bump-version.sh` | Rewrites `VERSION` + every listed manifest in lockstep; `--check` fails CI on drift. |
| `.github/workflows/release.yml` | After CI succeeds on `main`, tags the version and publishes a Release. |
| `.github/workflows/whats-new.yml` | After `Release` runs, refreshes the README "What's new" headline through an auto-merged PR. |
| `scripts/whats-new.sh` | Headline extractor + README block rewriter (the `whats-new:start/end` region). |
| `docs/releases/README.md` | The per-version release-notes convention. |

Yours (seeded once, never touched again):

| File | Role |
|---|---|
| `VERSION` | The single source of truth for your current version. Set it to your current number. |
| `.version-manifests` | The manifests that must match `VERSION`, one path per line. Edit to list yours. |
| `docs/releases/<x.y.z>.md` | Your hand-written notes for a release (optional per release). |

## Setup after install

1. Set `VERSION` to your plugin's current version (e.g. `echo 1.4.0 > VERSION`).
2. Edit `.version-manifests` to list every manifest that hardcodes the version (each must have
   exactly one `"version"` token). Run `scripts/bump-version.sh --check` until it is clean.
3. Ensure you have a CI workflow **named `CI`** (`name: CI`) that runs on pushes to `main` - the
   release waits for it to succeed there. `release.yml` is owned (refreshed on update), so adapt
   your workflow's name rather than editing `release.yml`'s `workflows:` line.
4. Wire `scripts/bump-version.sh --check` into that CI so drift is caught.
5. Add the "What's new" marker pair to your README once (the workflow rewrites between them):

   ```
   <!-- whats-new:start -->
   **0.0.0** - initial.
   <!-- whats-new:end -->
   ```

   It needs the org setting "Allow GitHub Actions to create and approve pull requests" so the
   workflow can open + self-merge its PR.

## Releasing

`scripts/bump-version.sh X.Y.Z` -> write `docs/releases/X.Y.Z.md` -> PR -> squash-merge. CI runs;
on success `release.yml` tags + publishes from your notes, then `whats-new.yml` refreshes the
README headline through an auto-merged PR. See `docs/releases/README.md`.
