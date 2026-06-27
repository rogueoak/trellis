#!/bin/sh
# Trellis compliance pass: find (and optionally fix) violations of the
# mechanically-checkable rules in docs/rules across the repo's tracked text.
# Dependency-free: POSIX sh + git + grep + sed, no Node/Python/binary required.
#
# Today the one checkable rule is guidelines.md's em/en-dash ban: an em-dash
# (U+2014) or en-dash (U+2013) in tracked text is a violation. As more rules
# ship a checker, extend this one script rather than spawning copies.
#
# Usage:
#   check-compliance.sh          report violations as file:line, exit 1 if any
#   check-compliance.sh --fix    rewrite em/en dashes to ASCII in place (best effort)
#
# Reusable as-is by a future pre-commit hook or CI: report mode's non-zero exit
# is the gate. Run from the repo root.
set -eu

fix=0
case "${1:-}" in
  --fix) fix=1 ;;
  "") ;;
  *) echo "usage: check-compliance.sh [--fix]" >&2; exit 2 ;;
esac

# Build the offending bytes here so this script file stays pure ASCII and does
# not flag itself. em = U+2014 (E2 80 94), en = U+2013 (E2 80 93).
em=$(printf '\342\200\224')
en=$(printf '\342\200\223')

# Optional skip list for content this repo does not author - e.g. another tool's
# vendored docs (Spectra lives under docs/spectra/). Developer-owned, gitignore-lite:
# blank and '#' lines ignored; a trailing-slash pattern skips a directory subtree;
# anything else is a glob matched against the path. Absent file = scan everything.
ignore_file="docs/rules/.compliance-ignore"
ignored() {
  [ -f "$ignore_file" ] || return 1
  while IFS= read -r pat || [ -n "$pat" ]; do
    case "$pat" in ''|'#'*) continue ;; esac
    case "$pat" in
      */) case "$1/" in "$pat"*) return 0 ;; esac ;;
      *)  case "$1" in $pat) return 0 ;; esac ;;
    esac
  done < "$ignore_file"
  return 1
}

# A tracked file is in scope when it is not skipped, is text (grep -I treats it as
# such), and contains a dash. git ls-files honors .gitignore and skips untracked.
in_scope() {
  ! ignored "$1" \
    && grep -Iq . "$1" 2>/dev/null \
    && grep -q -e "$em" -e "$en" "$1" 2>/dev/null
}

# Pass 1: act. Report each hit as file:line, or rewrite in place under --fix.
git ls-files -z | while IFS= read -r -d '' f; do
  [ -f "$f" ] && in_scope "$f" || continue
  if [ "$fix" -eq 1 ]; then
    # em-dash -> spaced hyphen, en-dash -> hyphen, then squeeze the doubled
    # spaces the em swap can introduce ("a  -  b" -> "a - b"). Best effort:
    # review the diff, since em-vs-comma and spacing are judgment calls.
    tmp="$f.trellis.tmp"
    sed -e "s/$em/ - /g" -e "s/$en/-/g" -e 's/  *-  */ - /g' "$f" > "$tmp"
    if cmp -s "$f" "$tmp"; then rm -f "$tmp"; else mv "$tmp" "$f"; echo "fixed: $f"; fi
  else
    grep -nF -e "$em" -e "$en" "$f" | while IFS= read -r line; do echo "$f:$line"; done
  fi
done

# Pass 2: verdict. The pipe above runs in a subshell, so counters there do not
# survive; recompute the offender count over the (now possibly fixed) tree.
hits=$(git ls-files -z | { n=0; while IFS= read -r -d '' f; do
  [ -f "$f" ] && in_scope "$f" && n=$((n + 1)) || continue
done; printf '%s' "$n"; })

if [ "$fix" -eq 1 ]; then
  if [ "$hits" -gt 0 ]; then
    echo "compliance: $hits file(s) still contain em/en dashes after --fix; fix by hand." >&2
    exit 1
  fi
  echo "compliance: em/en dashes rewritten to ASCII (best effort - review the diff)."
  exit 0
fi

if [ "$hits" -gt 0 ]; then
  echo "" >&2
  echo "compliance: $hits file(s) violate the em/en-dash ban (guidelines.md)." >&2
  echo "  run the pass with --fix to rewrite them to ASCII, then review the diff." >&2
  exit 1
fi
echo "compliance: clean - no em/en dashes in tracked text."
exit 0
