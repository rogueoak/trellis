#!/bin/sh
# Trellis template helper: list, apply, and refresh optional templates.
#
# Shared by the trellis-template (apply/list) and trellis-update (refresh) skills so the
# copy/registry logic lives in one tested place - the same one-script-no-drift discipline as
# install-hooks.sh and check-compliance.sh. Run from the consumer repo root.
#
# Usage:
#   template.sh <SRC> list             list available templates, marking applied ones
#   template.sh <SRC> apply <name>     apply a template (owned clobbers, seed copied once)
#   template.sh <SRC> refresh <name>   re-sync an applied template's owned files (+ prune)
#
# <SRC> is the Trellis plugin root (the dir holding templates/). A template name is a slug
# ([A-Za-z0-9_-]); anything else is rejected so it cannot be used to escape the repo root.
set -eu

SRC="${1:?usage: template.sh <SRC> <list|apply|refresh> [name]}"
cmd="${2:?usage: template.sh <SRC> <list|apply|refresh> [name]}"
name="${3:-}"

tpl_root="$SRC/templates"
reg="docs/rules/.trellis-templates"

valid_name() {
  case "$1" in
    "" | *[!A-Za-z0-9_-]*) return 1 ;;
    *) return 0 ;;
  esac
}

owned_files() { # list a template's owned files as repo-relative paths
  ( cd "$1/owned" && find . -type f | sed 's#^\./##' )
}

list_templates() {
  [ -d "$tpl_root" ] || { echo "no templates found at $tpl_root - is SRC right?" >&2; exit 1; }
  for tdir in "$tpl_root"/*/; do
    [ -d "$tdir/owned" ] || continue
    n=$(basename "$tdir")
    desc=$(sed -n '1s/^#* *//p' "$tdir/README.md" 2>/dev/null || true)
    if [ -f "$reg" ] && grep -qxF "$n" "$reg"; then mark=" (applied)"; else mark=""; fi
    printf '%s%s - %s\n' "$n" "$mark" "$desc"
  done
}

apply_template() {
  valid_name "$name" || { echo "invalid template name: '$name'" >&2; exit 1; }
  [ -d "$tpl_root/$name/owned" ] || { echo "no such template: $name - run with 'list' to see the available ones" >&2; exit 1; }
  [ -f docs/rules/.trellis-owned ] || { echo "no Trellis install found - run /trellis-install first" >&2; exit 1; }
  tdir="$tpl_root/$name"
  touch "$reg"
  cp -Rp "$tdir/owned/." .
  # Seed is copied per file: keep any target that already exists (never clobber) and report it.
  # Done by hand rather than `cp -Rn` because BSD cp returns non-zero when it skips, which would
  # fail this script under `set -e` on a re-apply.
  if [ -d "$tdir/seed" ]; then
    ( cd "$tdir/seed" && find . -type f | sed 's#^\./##' ) | while IFS= read -r f; do
      if [ -e "$f" ]; then
        echo "seed kept (already present): $f"
      else
        mkdir -p "$(dirname "$f")"
        cp -p "$tdir/seed/$f" "$f"
      fi
    done
  fi
  grep -qxF "$name" "$reg" || echo "$name" >> "$reg"
  owned_files "$tdir" > "docs/rules/.trellis-owned-$name"
  echo "applied template '$name'"
}

refresh_template() {
  valid_name "$name" || { echo "invalid template name: '$name'" >&2; exit 1; }
  tdir="$tpl_root/$name"
  owned_list="docs/rules/.trellis-owned-$name"
  if [ ! -d "$tdir/owned" ]; then
    echo "template '$name' no longer shipped - leaving its files in place" >&2
    return 0
  fi
  cp -Rp "$tdir/owned/." .
  # Prune owned files this template used to ship but no longer does.
  if [ -f "$owned_list" ]; then
    while IFS= read -r old; do
      if [ -n "$old" ] && [ ! -e "$tdir/owned/$old" ]; then rm -f "$old"; fi
    done < "$owned_list"
  fi
  owned_files "$tdir" > "$owned_list"
  echo "refreshed template '$name'"
}

case "$cmd" in
  list) list_templates ;;
  apply) apply_template ;;
  refresh) refresh_template ;;
  *) echo "unknown command: $cmd (use list|apply|refresh)" >&2; exit 1 ;;
esac
