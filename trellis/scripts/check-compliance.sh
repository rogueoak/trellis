#!/bin/sh
# Trellis compliance pass: find (and optionally fix) violations of the
# mechanically-checkable rules in docs/rules across the repo's tracked text.
# Dependency-free: POSIX sh + git + grep + sed, no Node/Python/binary required.
# Verified under dash, so it is safe as a CI / pre-commit gate.
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

# A tracked file is in scope when it is a regular file (not a symlink - we never
# read or rewrite through one), is not skipped, is text (grep -I treats it so),
# and contains a dash. "-- $f" keeps a hostile filename (e.g. one starting with
# '-') from being parsed as an option by grep.
in_scope() {
  [ ! -L "$1" ] || return 1
  ! ignored "$1" || return 1
  grep -Iq . -- "$1" 2>/dev/null || return 1
  grep -q -e "$em" -e "$en" -- "$1" 2>/dev/null
}

# Enumerate tracked files newline-delimited (POSIX read has no -z/-d, so the
# NUL form is not portable to dash). git ls-files honors .gitignore and, with
# core.quotePath on by default, C-quotes any path with newlines or control
# bytes; such a quoted name fails the [ -f ] test below and is skipped rather
# than mis-handled. Plain spaces are not quoted and read fine.
offenders=$(mktemp)
trap 'rm -f "$offenders"' EXIT
git ls-files | while IFS= read -r f; do
  if [ -f "$f" ] && in_scope "$f"; then printf '%s\n' "$f"; fi
done > "$offenders"
count=$(wc -l < "$offenders" | tr -d ' ')

# Report mode (default): print every hit as file:line, change nothing.
if [ "$fix" -eq 0 ]; then
  if [ "$count" -eq 0 ]; then
    echo "compliance: clean - no em/en dashes in tracked text."
    exit 0
  fi
  while IFS= read -r f; do
    grep -nF -e "$em" -e "$en" -- "$f" | while IFS= read -r line; do
      printf '%s:%s\n' "$f" "$line"
    done
  done < "$offenders"
  echo "" >&2
  echo "compliance: $count file(s) violate the em/en-dash ban (guidelines.md)." >&2
  echo "  run the pass with --fix to rewrite them to ASCII, then review the diff." >&2
  exit 1
fi

# Fix mode: rewrite em/en dashes to ASCII. em-dash -> spaced hyphen (consuming
# any spaces already around it, so "a - b" stays single-spaced); en-dash ->
# hyphen. The substitutions only touch the dash and its immediate spaces, so
# unrelated aligned text on other lines is left alone. Best effort: review the
# diff, since em-vs-comma is a judgment call.
if [ "$count" -eq 0 ]; then
  echo "compliance: clean - no em/en dashes to fix."
  exit 0
fi
changed=0
while IFS= read -r f; do
  case "$f" in */*) dir=${f%/*} ;; *) dir=. ;; esac
  # mktemp gives an unpredictable, freshly-created regular file (never a planted
  # symlink); the leading './' neutralizes a dir name that starts with '-'.
  tmp=$(mktemp "./$dir/.trellis-compliance.XXXXXX")
  if sed -e "s/ *$em */ - /g" -e "s/$en/-/g" < "$f" > "$tmp"; then
    if cmp -s -- "$f" "$tmp"; then
      rm -f -- "$tmp"
    else
      mv -- "$tmp" "$f"
      printf 'fixed: %s\n' "$f"
      changed=$((changed + 1))
    fi
  else
    rm -f -- "$tmp"
    echo "compliance: failed to rewrite $f; left as-is." >&2
  fi
done < "$offenders"

# Confirm none remain (a dash the heuristic missed, or a write that failed).
remaining=$(git ls-files | { n=0; while IFS= read -r f; do
  [ -f "$f" ] && in_scope "$f" && n=$((n + 1)) || continue
done; printf '%s' "$n"; })
if [ "$remaining" -gt 0 ]; then
  echo "compliance: $remaining file(s) still contain em/en dashes after --fix; fix by hand." >&2
  exit 1
fi
echo "compliance: rewrote $changed file(s) to ASCII (best effort - review the diff)."
exit 0
