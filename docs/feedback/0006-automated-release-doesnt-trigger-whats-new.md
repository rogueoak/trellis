# 0006 - The automated release did not refresh the README "What's new"

## Symptom
After 0005, merging the `0.4.0` bump auto-tagged and published the Release, but the README "What's
new" block stayed at `0.3.0`. The `docs/overview` claim that a bump "fans out to tag -> Release ->
README headline" did not hold for the automated release.

## Root cause
Two independent gaps, both surfaced only by dogfooding the real pipeline:

1. **A `GITHUB_TOKEN`-created event does not trigger other workflows.** `release.yml` creates the
   Release with the ambient `GITHUB_TOKEN`. GitHub deliberately suppresses workflow triggers from
   events created by that token (to prevent recursion), so the `release: [published]`-triggered
   `whats-new.yml` never fired. Spectra's equivalent only ever worked because its releases were
   created by hand with a personal token.
2. **`whats-new.yml` pushed straight to `main`.** Even when it did run, it did `git push` to a
   ruleset-protected branch, which rejects direct pushes (`push declined due to repository rule
   violations`). It had been failing on every release.

## Fix
- Rewrote the canonical `whats-new.yml` (now owned by the plugin-release template) to trigger on
  **`workflow_run` of the `Release` workflow** - which fires regardless of how the release was
  created - and to land the change through an **auto-created, self-squash-merged PR** instead of a
  direct push.
- Unified `whats-new.sh` (neutral `<!-- whats-new:start/end -->` markers) into the template as an
  owned file, so both Trellis and Spectra run the same one.

## Learning
- `GITHUB_TOKEN`-created events (releases, pushes, tags) do not trigger further workflows. To run
  work *after* an automated step, key on `workflow_run` of the workflow that did it, not on the
  domain event it produced.
- A workflow that writes to a ruleset-protected branch must go through a PR (open + self-merge),
  never a direct push - the same constraint human contributors have.
- Dogfooding the *whole* pipeline end-to-end (not just the unit it changed) is what exposed both;
  a green unit test would not have.
