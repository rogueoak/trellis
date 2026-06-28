#!/bin/sh
# Tests for template.sh (the list/apply/refresh helper the trellis-template and trellis-update
# skills share). Dependency-free; run under any POSIX shell:
#   sh trellis/scripts/template.test.sh
# Run under dash too (dash trellis/scripts/template.test.sh) to guard the POSIX contract.
set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo=$(CDPATH= cd -- "$here/../.." && pwd)
SUT="$repo/trellis/scripts/template.sh"
SRC="$repo/trellis"   # the plugin root holding templates/

pass=0
fail=0
check() { # check <description> <expected-exit> <actual-exit>
  if [ "$2" -eq "$3" ]; then pass=$((pass + 1)); else
    fail=$((fail + 1)); echo "FAIL: $1 (expected exit $2, got $3)"; fi
}
ok() { # ok <description> <0-if-true>
  if [ "$2" -eq 0 ]; then pass=$((pass + 1)); else
    fail=$((fail + 1)); echo "FAIL: $1"; fi
}

# A throwaway consumer repo that already has Trellis installed (the apply path requires it).
sandbox() {
  d=$(mktemp -d)
  mkdir -p "$d/docs/rules"
  echo "guidelines.md" > "$d/docs/rules/.trellis-owned"
  echo "$d"
}

# --- list shows both shipped templates -------------------------------------
d=$(sandbox)
out=$(cd "$d" && sh "$SUT" "$SRC" list)
case "$out" in *web-app*) ok "list shows web-app" 0 ;; *) ok "list shows web-app" 1 ;; esac
case "$out" in *plugin-release*) ok "list shows plugin-release" 0 ;; *) ok "list shows plugin-release" 1 ;; esac
rm -rf "$d"

# --- apply web-app lands owned + seed + registry ---------------------------
d=$(sandbox)
( cd "$d" && sh "$SUT" "$SRC" apply web-app ) >/dev/null 2>&1 && rc=0 || rc=$?
check "apply web-app exits 0" 0 "$rc"
ok "owned conventions installed" "$([ -f "$d/docs/templates/web-app/conventions.md" ] && echo 0 || echo 1)"
ok "seed package.json installed" "$([ -f "$d/package.json" ] && echo 0 || echo 1)"
ok "seed app/page.tsx installed" "$([ -f "$d/app/page.tsx" ] && echo 0 || echo 1)"
ok "registry records web-app" "$(grep -qxF web-app "$d/docs/rules/.trellis-templates" && echo 0 || echo 1)"
ok "owned-list lists the conventions doc" "$(grep -qxF 'docs/templates/web-app/conventions.md' "$d/docs/rules/.trellis-owned-web-app" && echo 0 || echo 1)"
rm -rf "$d"

# --- apply is idempotent (registry not duplicated) -------------------------
d=$(sandbox)
( cd "$d" && sh "$SUT" "$SRC" apply web-app && sh "$SUT" "$SRC" apply web-app ) >/dev/null 2>&1
count=$(grep -cxF web-app "$d/docs/rules/.trellis-templates")
ok "registry has web-app exactly once after double apply" "$([ "$count" -eq 1 ] && echo 0 || echo 1)"
rm -rf "$d"

# --- seed is never clobbered, and the keep is reported ---------------------
d=$(sandbox)
echo '{"name":"mine"}' > "$d/package.json"
out=$(cd "$d" && sh "$SUT" "$SRC" apply web-app)
ok "existing seed file left untouched" "$(grep -q '"name":"mine"' "$d/package.json" && echo 0 || echo 1)"
case "$out" in *"seed kept (already present): package.json"*) ok "skipped seed is reported" 0 ;; *) ok "skipped seed is reported" 1 ;; esac
rm -rf "$d"

# --- a path-traversal name is rejected before any write --------------------
d=$(sandbox)
( cd "$d" && sh "$SUT" "$SRC" apply ../evil ) >/dev/null 2>&1 && rc=0 || rc=$?
check "traversal name rejected (non-zero exit)" 1 "$rc"
ok "no registry written for a rejected name" "$([ ! -f "$d/docs/rules/.trellis-templates" ] && echo 0 || echo 1)"
rm -rf "$d"

# --- unknown template errors -----------------------------------------------
d=$(sandbox)
( cd "$d" && sh "$SUT" "$SRC" apply nope ) >/dev/null 2>&1 && rc=0 || rc=$?
check "unknown template exits non-zero" 1 "$rc"
rm -rf "$d"

# --- apply without an install is refused -----------------------------------
d=$(mktemp -d)
( cd "$d" && sh "$SUT" "$SRC" apply web-app ) >/dev/null 2>&1 && rc=0 || rc=$?
check "apply without Trellis install exits non-zero" 1 "$rc"
rm -rf "$d"

# --- refresh restores a tampered owned file, leaves seed alone -------------
d=$(sandbox)
( cd "$d" && sh "$SUT" "$SRC" apply web-app ) >/dev/null 2>&1
echo "TAMPERED" > "$d/docs/templates/web-app/conventions.md"
echo "MY EDIT" >> "$d/package.json"
( cd "$d" && sh "$SUT" "$SRC" refresh web-app ) >/dev/null 2>&1 && rc=0 || rc=$?
check "refresh web-app exits 0" 0 "$rc"
ok "owned conventions refreshed (tamper gone)" "$(grep -q TAMPERED "$d/docs/templates/web-app/conventions.md" && echo 1 || echo 0)"
ok "seed left untouched by refresh" "$(grep -q 'MY EDIT' "$d/package.json" && echo 0 || echo 1)"
rm -rf "$d"

# --- refresh prunes an owned file no longer shipped ------------------------
d=$(sandbox)
( cd "$d" && sh "$SUT" "$SRC" apply web-app ) >/dev/null 2>&1
mkdir -p "$d/docs/templates/web-app"
echo stale > "$d/docs/templates/web-app/old.md"
printf 'docs/templates/web-app/conventions.md\ndocs/templates/web-app/old.md\n' > "$d/docs/rules/.trellis-owned-web-app"
( cd "$d" && sh "$SUT" "$SRC" refresh web-app ) >/dev/null 2>&1
ok "stale owned file pruned on refresh" "$([ ! -e "$d/docs/templates/web-app/old.md" ] && echo 0 || echo 1)"
rm -rf "$d"

# --- the dogfood diff CI runs still applies (plugin-release too) -----------
d=$(sandbox)
( cd "$d" && sh "$SUT" "$SRC" apply plugin-release ) >/dev/null 2>&1 && rc=0 || rc=$?
check "apply plugin-release exits 0" 0 "$rc"
ok "plugin-release owned script installed" "$([ -f "$d/scripts/bump-version.sh" ] && echo 0 || echo 1)"
ok "plugin-release seed VERSION installed" "$([ -f "$d/VERSION" ] && echo 0 || echo 1)"
rm -rf "$d"

echo ""
echo "template.test.sh: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
