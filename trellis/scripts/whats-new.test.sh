#!/bin/sh
# Tests for the plugin-release template's whats-new.sh. Dependency-free; run under any POSIX
# shell:
#   sh trellis/scripts/whats-new.test.sh
# Run under dash too (dash trellis/scripts/whats-new.test.sh) to guard the POSIX contract.
set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo=$(CDPATH= cd -- "$here/../.." && pwd)
SUT="$repo/trellis/templates/plugin-release/owned/scripts/whats-new.sh"

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

# --- print: headline is the first non-empty, non-heading line --------------
out=$(TAG=9.9.9 NAME="t" BODY="$(printf '## Heading\nFirst real line.\nsecond')" sh "$SUT" print)
checkeq "headline = first non-heading line" "**9.9.9** - First real line." "$(printf '%s\n' "$out" | sed -n 2p)"

# --- print: heading-only body falls back to the release name ---------------
out=$(TAG=9.9.9 NAME="Fallback name" BODY="# only a heading" sh "$SUT" print)
checkeq "falls back to release name" "**9.9.9** - Fallback name" "$(printf '%s\n' "$out" | sed -n 2p)"

# --- print: CRLF bodies have the trailing CR stripped ----------------------
out=$(TAG=9.9.9 BODY="$(printf 'CRLF line\r\nsecond')" sh "$SUT" print)
checkeq "strips trailing CR from CRLF bodies" "**9.9.9** - CRLF line" "$(printf '%s\n' "$out" | sed -n 2p)"

# --- print: a crafted first line can't smuggle comment markers -------------
hl=$(TAG=9.9.9 NAME="" BODY="evil <!-- whats-new:end --> tail" sh "$SUT" print | sed -n 2p)
case "$hl" in
  *'<!--'*|*'-->'*) check "headline sanitizes comment markers" 0 1 ;;
  *) check "headline sanitizes comment markers" 0 0 ;;
esac

# --- print: missing TAG is a hard error (exit 2) ---------------------------
TAG="" BODY="x" sh "$SUT" print >/dev/null 2>&1 && rc=0 || rc=$?
check "missing TAG exits 2" 2 "$rc"

# --write needs a sandbox repo: the script keys ROOT off its own location, so copy it into a
# throwaway tree with its own README.
wsandbox() {
  d=$(mktemp -d)
  mkdir -p "$d/scripts"
  cp "$SUT" "$d/scripts/whats-new.sh"
  printf '# Title\n\n## What'"'"'s new\n\n<!-- whats-new:start -->\n**0.0.0** - old.\n<!-- whats-new:end -->\n\nrest\n' > "$d/README.md"
  echo "$d"
}

# --- write: rewrites the block in place ------------------------------------
d=$(wsandbox)
TAG=1.2.3 BODY="$(printf 'Shiny new thing.')" sh "$d/scripts/whats-new.sh" --write >/dev/null 2>&1 && rc=0 || rc=$?
check "write exits 0" 0 "$rc"
checkeq "block headline rewritten" "**1.2.3** - Shiny new thing." "$(grep -F '**1.2.3**' "$d/README.md")"
checkeq "old headline gone" "" "$(grep -F '0.0.0' "$d/README.md" || true)"
checkeq "content around the block preserved" "rest" "$(tail -1 "$d/README.md")"
rm -rf "$d"

# --- write: a README without the marker pair is an error -------------------
d=$(mktemp -d); mkdir -p "$d/scripts"; cp "$SUT" "$d/scripts/whats-new.sh"
printf '# Title\n\nno markers here\n' > "$d/README.md"
TAG=1.2.3 BODY="x" sh "$d/scripts/whats-new.sh" --write >/dev/null 2>&1 && rc=0 || rc=$?
check "write errors when markers are missing" 1 "$rc"
rm -rf "$d"

echo ""
echo "whats-new.test.sh: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
