#!/bin/sh
# Trellis hook installer. Run from the plugin source by trellis-install / trellis-update;
# NOT copied into the consumer repo. Copies the shipped git hooks into the repo's resolved
# hooks dir, displacing - never clobbering - any foreign hook of the same name.
# Usage: sh install-hooks.sh <plugin-src-root>
set -eu

SRC="${1:?usage: install-hooks.sh <plugin-src-root>}"
HOOKS="$(git rev-parse --git-path hooks)"
mkdir -p "$HOOKS"

# The git hooks Trellis ships and manages.
for name in commit-msg; do
  src="$SRC/hooks/$name"
  dest="$HOOKS/$name"
  [ -f "$src" ] || continue

  # A foreign hook (no Trellis marker on its first lines) is moved aside so Trellis can chain
  # to it. If the aside slot is taken, refuse rather than destroy either hook.
  if [ -e "$dest" ] && ! head -n 2 "$dest" 2>/dev/null | grep -q "^# Trellis $name hook:"; then
    if [ -e "$dest.local" ]; then
      echo "trellis: $dest.local already exists; leaving your $name hook untouched and NOT installing Trellis's. Resolve by hand." >&2
      continue
    fi
    mv "$dest" "$dest.local"
  fi

  rm -f "$dest"          # break a symlink rather than copy/chmod through it
  cp "$src" "$dest"
  chmod +x "$dest"
done

if hp=$(git config core.hooksPath 2>/dev/null) && [ -n "$hp" ]; then
  echo "trellis: core.hooksPath is '$hp' (a hook manager like husky/lefthook); git runs hooks from there, so hooks in $HOOKS may be shadowed - wire them into '$hp' too." >&2
fi
