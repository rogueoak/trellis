#!/bin/sh
# Tests for the plugin-release template's bump-version.sh. Dependency-free; run under any POSIX
# shell:
#   sh trellis/scripts/bump-version.test.sh
# Run it under dash too (dash trellis/scripts/bump-version.test.sh) to guard the POSIX contract.
set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo=$(CDPATH= cd -- "$here/../.." && pwd)
SUT="$repo/trellis/templates/plugin-release/owned/scripts/bump-version.sh"

pass=0
fail=0
check() { # check <description> <expected-exit> <actual-exit>
  if [ "$2" -eq "$3" ]; then pass=$((pass + 1)); else
    fail=$((fail + 1)); echo "FAIL: $1 (expected exit $2, got $3)"; fi
}
checkeq() { # checkeq <description> <expected> <actual>
  if [ "$2" = "$3" ]; then pass=$((pass + 1)); else
    fail=$((fail + 1)); echo "FAIL: $1"; echo "  expected: $2"; echo "  actual:   $3"; fi
}

# A throwaway plugin tree: VERSION, a manifest list, and two manifests with one version token
# each (one top-level, one nested under plugins[]).
sandbox() {
  d=$(mktemp -d)
  printf '%s\n' "${1:-1.0.0}" > "$d/VERSION"
  mkdir -p "$d/a" "$d/b"
  printf '{\n  "name": "p",\n  "version": "%s"\n}\n' "${1:-1.0.0}" > "$d/a/plugin.json"
  printf '{\n  "plugins": [\n    { "name": "p", "version": "%s" }\n  ]\n}\n' "${1:-1.0.0}" > "$d/b/market.json"
  printf 'a/plugin.json\nb/market.json\n' > "$d/.version-manifests"
  echo "$d"
}
ver() { grep -o '"version": *"[^"]*"' "$1" | head -1 | sed 's/.*"\([^"]*\)"$/\1/'; }

# --- --check passes on a synced tree ---------------------------------------
d=$(sandbox 1.0.0)
BUMP_VERSION_ROOT="$d" sh "$SUT" --check >/dev/null 2>&1 && rc=0 || rc=$?
check "--check exits 0 when VERSION matches every manifest" 0 "$rc"
rm -rf "$d"

# --- no-arg prints the current version -------------------------------------
d=$(sandbox 2.5.1)
checkeq "no-arg prints VERSION" "2.5.1" "$(BUMP_VERSION_ROOT="$d" sh "$SUT")"
rm -rf "$d"

# --- write propagates to VERSION + every listed manifest -------------------
d=$(sandbox 1.0.0)
BUMP_VERSION_ROOT="$d" sh "$SUT" 9.9.9 >/dev/null 2>&1 && rc=0 || rc=$?
check "write X.Y.Z exits 0" 0 "$rc"
checkeq "VERSION updated" "9.9.9" "$(cat "$d/VERSION")"
checkeq "manifest a updated" "9.9.9" "$(ver "$d/a/plugin.json")"
checkeq "manifest b updated" "9.9.9" "$(ver "$d/b/market.json")"
BUMP_VERSION_ROOT="$d" sh "$SUT" --check >/dev/null 2>&1 && rc=0 || rc=$?
check "--check converges after write" 0 "$rc"
rm -rf "$d"

# --- semver gate: rejects bad arguments ------------------------------------
d=$(sandbox 1.0.0)
for bad in "v1.2.3" "1.2" "1.2.3.4" "nope" ""; do
  BUMP_VERSION_ROOT="$d" sh "$SUT" "$bad" >/dev/null 2>&1 && rc=0 || rc=$?
  check "rejects '$bad'" 1 "$rc"
done
# a multiline argument whose first line is valid must still be rejected
BUMP_VERSION_ROOT="$d" sh "$SUT" "$(printf '1.2.3\nx')" >/dev/null 2>&1 && rc=0 || rc=$?
check "rejects a multiline argument" 1 "$rc"
checkeq "rejected args leave VERSION untouched" "1.0.0" "$(cat "$d/VERSION")"
rm -rf "$d"

# --- negative drift: a hand-edited manifest fails --check ------------------
d=$(sandbox 1.0.0)
printf '{\n  "name": "p",\n  "version": "1.0.1"\n}\n' > "$d/a/plugin.json"   # drift one manifest
BUMP_VERSION_ROOT="$d" sh "$SUT" --check >/dev/null 2>&1 && rc=0 || rc=$?
check "--check exits 1 when a manifest drifts" 1 "$rc"
rm -rf "$d"

# --- two version tokens in one manifest trips the guard --------------------
d=$(sandbox 1.0.0)
printf '{\n  "version": "1.0.0",\n  "deps": { "x": { "version": "1.0.0" } }\n}\n' > "$d/a/plugin.json"
BUMP_VERSION_ROOT="$d" sh "$SUT" --check >/dev/null 2>&1 && rc=0 || rc=$?
check "--check exits 1 on a two-token manifest" 1 "$rc"
rm -rf "$d"

# --- atomic write: a bad manifest aborts the WHOLE write, no half-bump ------
# manifest b is fine, a has two tokens. A write must validate all in memory and touch nothing,
# so VERSION and the good manifest stay at the old value (no partial bump).
d=$(sandbox 1.0.0)
printf '{\n  "version": "1.0.0",\n  "deps": { "x": { "version": "1.0.0" } }\n}\n' > "$d/a/plugin.json"
BUMP_VERSION_ROOT="$d" sh "$SUT" 9.9.9 >/dev/null 2>&1 && rc=0 || rc=$?
check "write aborts on a two-token manifest" 1 "$rc"
checkeq "aborted write leaves VERSION unchanged" "1.0.0" "$(cat "$d/VERSION")"
checkeq "aborted write leaves the good manifest unchanged" "1.0.0" "$(ver "$d/b/market.json")"
rm -rf "$d"

# --- .version-manifests ignores comments and blank lines -------------------
d=$(sandbox 1.0.0)
printf '# a comment\n\na/plugin.json\n   \nb/market.json  # trailing\n' > "$d/.version-manifests"
BUMP_VERSION_ROOT="$d" sh "$SUT" --check >/dev/null 2>&1 && rc=0 || rc=$?
check "--check parses .version-manifests with comments and blanks" 0 "$rc"
rm -rf "$d"

# --- a missing manifest is an error ----------------------------------------
d=$(sandbox 1.0.0)
rm -f "$d/b/market.json"
BUMP_VERSION_ROOT="$d" sh "$SUT" --check >/dev/null 2>&1 && rc=0 || rc=$?
check "--check exits 1 when a listed manifest is missing" 1 "$rc"
rm -rf "$d"

# --- a missing .version-manifests is an error ------------------------------
d=$(sandbox 1.0.0)
rm -f "$d/.version-manifests"
BUMP_VERSION_ROOT="$d" sh "$SUT" --check >/dev/null 2>&1 && rc=0 || rc=$?
check "--check exits non-zero without .version-manifests" 1 "$rc"
rm -rf "$d"

echo ""
echo "bump-version.test.sh: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
