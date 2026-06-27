#!/bin/sh
# Tests for check-compliance.sh. Dependency-free; run under any POSIX shell:
#   sh trellis/scripts/check-compliance.test.sh
# Run it under dash too (dash trellis/scripts/check-compliance.test.sh) to guard
# the POSIX-only contract the script promises for CI / pre-commit reuse.
set -eu

# Resolve the script under test relative to this test file.
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SUT="$here/check-compliance.sh"
em=$(printf '\342\200\224')
en=$(printf '\342\200\223')

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

# Each test runs in a throwaway git repo so git ls-files behaves as in real use.
newrepo() {
  d=$(mktemp -d)
  cd "$d"
  git init -q
  git config user.email t@t.t
  git config user.name t
}

# --- report mode: reports file:line and exits 1 -----------------------------
newrepo
printf 'alpha%sbeta\nclean line\nrange 1%s5\n' "$em" "$en" > doc.md
git add doc.md; git commit -qm i
out=$(sh "$SUT") && rc=0 || rc=$?
check "report exits 1 on violations" 1 "$rc"
checkeq "report shows em-dash line" "doc.md:1:alpha${em}beta" "$(printf '%s\n' "$out" | sed -n 1p)"
checkeq "report shows en-dash line" "doc.md:3:range 1${en}5" "$(printf '%s\n' "$out" | sed -n 2p)"

# --- clean repo: exits 0 ----------------------------------------------------
newrepo
printf 'all ascii here\n' > doc.md
git add doc.md; git commit -qm i
sh "$SUT" >/dev/null && rc=0 || rc=$?
check "clean repo exits 0" 0 "$rc"

# --- fix mode: rewrites, idempotent re-run is clean -------------------------
newrepo
printf 'a%sb\nx %s y\nrange 1%s5\n' "$em" "$em" "$en" > doc.md
git add doc.md; git commit -qm i
sh "$SUT" --fix >/dev/null && rc=0 || rc=$?
check "fix exits 0" 0 "$rc"
checkeq "em no-space -> spaced hyphen" "a - b" "$(sed -n 1p doc.md)"
checkeq "em with spaces stays single-spaced" "x - y" "$(sed -n 2p doc.md)"
checkeq "en-dash -> hyphen" "range 1-5" "$(sed -n 3p doc.md)"
sh "$SUT" >/dev/null && rc=0 || rc=$?
check "re-run after fix is clean" 0 "$rc"

# --- fix must not reflow unrelated aligned lines (tester's major) -----------
newrepo
printf 'title%shere\n-h    is a flag\n' "$em" > doc.md
git add doc.md; git commit -qm i
sh "$SUT" --fix >/dev/null
checkeq "aligned spaces on other lines untouched" "-h    is a flag" "$(sed -n 2p doc.md)"

# --- no-op fix on a clean repo reports honestly, exits 0 --------------------
newrepo
printf 'ascii only\n' > doc.md
git add doc.md; git commit -qm i
out=$(sh "$SUT" --fix) && rc=0 || rc=$?
check "no-op fix exits 0" 0 "$rc"
checkeq "no-op fix says nothing to fix" "compliance: clean - no em/en dashes to fix." "$out"

# --- binary files are skipped -----------------------------------------------
newrepo
printf 'bin%s\000more\n' "$em" > data.bin
git add data.bin; git commit -qm i
sh "$SUT" >/dev/null && rc=0 || rc=$?
check "binary file skipped (clean)" 0 "$rc"

# --- untracked files are skipped --------------------------------------------
newrepo
printf 'tracked clean\n' > a.md
git add a.md; git commit -qm i
printf 'untracked%sdash\n' "$em" > b.md
sh "$SUT" >/dev/null && rc=0 || rc=$?
check "untracked file skipped (clean)" 0 "$rc"

# --- symlinks are skipped, never rewritten (security) -----------------------
newrepo
printf 'target%sdash\n' "$em" > real.md
ln -s real.md link.md
git add real.md link.md; git commit -qm i
mkdir -p docs/rules
printf 'real.md\n' > docs/rules/.compliance-ignore   # ignore the real file...
git add docs/rules/.compliance-ignore
sh "$SUT" >/dev/null && rc=0 || rc=$?
check "symlink not followed (link skipped, real ignored => clean)" 0 "$rc"
checkeq "symlink still a symlink" "link" "$([ -L link.md ] && echo link || echo regular)"

# --- ignore file skips a directory subtree ----------------------------------
newrepo
mkdir -p vendor docs/rules
printf 'vendored%sdash\n' "$em" > vendor/x.md
printf 'docs/rules/.compliance-ignore\nvendor/\n' > docs/rules/.compliance-ignore
git add -A; git commit -qm i
sh "$SUT" >/dev/null && rc=0 || rc=$?
check "ignore-file dir pattern skips subtree (clean)" 0 "$rc"

# --- hostile filename starting with '-' is not parsed as an option ----------
newrepo
printf 'dash%shere\n' "$em" > ./-rf.md
git add ./-rf.md; git commit -qm i
sh "$SUT" --fix >/dev/null && rc=0 || rc=$?
check "filename starting with - handled (fix exits 0)" 0 "$rc"
checkeq "hostile filename fixed" "dash - here" "$(sed -n 1p ./-rf.md)"

# --- bad argument: usage, exit 2 --------------------------------------------
newrepo
git commit -q --allow-empty -m i
sh "$SUT" --bogus >/dev/null 2>&1 && rc=0 || rc=$?
check "bad arg exits 2" 2 "$rc"

echo ""
echo "check-compliance.test.sh: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
