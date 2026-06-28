# 0006 - Fold "What's new" into the plugin-release template (plan)

Source: `docs/specs/0006-whats-new-in-release-template.md`.

## Steps
1. **Plan** (this).
2. **Canonical `whats-new.sh`** (owned) - Spectra's tested script with neutral markers
   `<!-- whats-new:start/end -->`; reframed as template-owned. [done]
3. **`whats-new.yml`** (owned) - `workflow_run` on `["Release"]`, `conclusion == success`;
   checkout default branch (SHA-pinned); read `VERSION`, `gh release view "$v"` (exit 0 if none),
   `whats-new.sh --write` with TAG/NAME/BODY; open + self-squash-merge `chore/whats-new-<v>`.
   Job-scoped `contents: write` + `pull-requests: write`. [done]
4. **`whats-new.test.sh`** (Trellis idiom) - headline/first-line, name fallback, CRLF, marker
   sanitize, required TAG, --write rewrite + missing-markers error. [done]
5. **Trellis re-adoption / dogfood:**
   - Copy the two new owned files to functional paths (`scripts/whats-new.sh`,
     `.github/workflows/whats-new.yml`), replacing the old `whats-new.yml`.
   - Swap the README markers `<!-- whats-new -->`/`<!-- /whats-new -->` ->
     `<!-- whats-new:start -->`/`<!-- whats-new:end -->`.
   - Extend `docs/rules/.trellis-owned-plugin-release` (regen from owned/).
   - Wire `whats-new.test.sh` into `.github/workflows/ci.yml`.
6. **Correct 0005 docs:** `docs/overview/architecture.md` + `features.md` - the pipeline fans out
   to the README headline only via this workflow_run + PR path (not a release-triggered job).
7. **Feedback + learning:** `docs/feedback/000N-*` capturing the two gotchas (GITHUB_TOKEN events
   do not trigger workflows; a protected main needs a PR, not a push); roll into
   `docs/overview/learnings.md` (general form).
8. **Release 0.4.1:** `scripts/bump-version.sh 0.4.1`; write `docs/releases/0.4.1.md`; on merge the
   pipeline tags 0.4.1, and whats-new now refreshes the README to the 0.4.1 headline - the proof.

## Verify
- `whats-new.test.sh` + `bump-version.test.sh` + `check-compliance.test.sh` pass (sh + dash).
- `bump-version.sh --check` clean; dogfood diff (installed == owned) clean for all owned files.
- `ci.yml` runs all three test suites; compliance pass clean; YAML valid.
- README has exactly one `<!-- whats-new:start/end -->` pair.

## Review
Personas (engineer/tester/architect/security): engineer (workflow shell + gh fetch), tester
(whats-new.test coverage), architect (the workflow_run composition + marker unification + owned
boundary), security (the new write+PR job's privilege, SHA-pin, injection via release body).
