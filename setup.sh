#!/usr/bin/env bash
# Canonical location for this repo is ~/.ai-agents. Clone anywhere and run
# this script; it relocates itself there if needed, then wires the machine-
# level symlinks Ruler and Claude Code expect. Safe to re-run (idempotent).
#
#   git clone <remote> ~/wherever && ~/wherever/setup.sh          # setup (default)
#   ~/.ai-agents/setup.sh remove                                  # tear down
set -euo pipefail

CMD="${1:-setup}"
CANONICAL_DIR="$HOME/.ai-agents"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
  local target="$1" link_path="$2"
  mkdir -p "$(dirname "$link_path")"

  if [ -L "$link_path" ]; then
    if [ "$(readlink "$link_path")" = "$target" ]; then
      echo "ok      $link_path -> $target"
      return
    fi
    echo "relink  $link_path (was -> $(readlink "$link_path"))"
    ln -sfn "$target" "$link_path"
    return
  fi

  if [ -e "$link_path" ]; then
    local backup="${link_path}.bak-$(date +%Y%m%d%H%M%S)"
    mv "$link_path" "$backup"
    ln -s "$target" "$link_path"
    echo "linked  $link_path -> $target (existing content backed up to $backup)"
    return
  fi

  ln -s "$target" "$link_path"
  echo "linked  $link_path -> $target"
}

SKILL_ALIAS_START="# >>> ai-agents: skill-add alias >>>"
SKILL_ALIAS_END="# <<< ai-agents: skill-add alias <<<"
SKILL_ALIAS_BODY='skill-add() { npx skills add "$@" -g -a claude-code --copy -y; }'
RC_FILES=("$HOME/.zshrc" "$HOME/.bashrc")

add_alias_block() {
  local rc="$1"
  [ -f "$rc" ] || return 0

  if grep -qF "$SKILL_ALIAS_START" "$rc"; then
    echo "ok      skill-add alias already in $rc"
    return
  fi

  {
    echo ""
    echo "$SKILL_ALIAS_START"
    echo "$SKILL_ALIAS_BODY"
    echo "$SKILL_ALIAS_END"
  } >> "$rc"
  echo "added   skill-add alias to $rc"
}

remove_alias_block() {
  local rc="$1"
  [ -f "$rc" ] || return 0

  if ! grep -qF "$SKILL_ALIAS_START" "$rc"; then
    echo "skip    skill-add alias not in $rc (absent)"
    return
  fi

  local tmp
  tmp="$(mktemp)"
  awk -v start="$SKILL_ALIAS_START" -v end="$SKILL_ALIAS_END" '
    $0 == start { skip=1; next }
    $0 == end { skip=0; next }
    skip { next }
    { print }
  ' "$rc" > "$tmp"
  mv "$tmp" "$rc"
  echo "removed skill-add alias from $rc"
}

unlink_managed() {
  local target="$1" link_path="$2"

  if [ ! -e "$link_path" ] && [ ! -L "$link_path" ]; then
    echo "skip    $link_path (absent)"
    return
  fi

  if [ ! -L "$link_path" ]; then
    echo "skip    $link_path (not a symlink, left untouched)" >&2
    return
  fi

  if [ "$(readlink "$link_path")" != "$target" ]; then
    echo "skip    $link_path (points elsewhere: $(readlink "$link_path"))" >&2
    return
  fi

  rm -f "$link_path"
  echo "removed $link_path"
}

do_setup() {
  if [ "$REPO_DIR" != "$CANONICAL_DIR" ]; then
    if [ -L "$CANONICAL_DIR" ]; then
      echo "Removing stale symlink at $CANONICAL_DIR"
      rm -f "$CANONICAL_DIR"
    elif [ -e "$CANONICAL_DIR" ]; then
      echo "error: $CANONICAL_DIR already exists and isn't this repo ($REPO_DIR)." >&2
      echo "Resolve manually (merge or remove it), then re-run setup.sh." >&2
      exit 1
    fi
    echo "Relocating repo: $REPO_DIR -> $CANONICAL_DIR"
    mv "$REPO_DIR" "$CANONICAL_DIR"
    exec "$CANONICAL_DIR/setup.sh" setup
  fi

  echo "Repo is at its canonical location: $REPO_DIR"
  echo

  # Ruler's global fallback: used when a project runs `ruler apply` without a
  # local .ruler/ — rules only, not skills (see README).
  link "$REPO_DIR/core" "$HOME/.config/ruler"

  # Claude Code's own native global skills folder — independent of Ruler.
  link "$REPO_DIR/core/skills" "$HOME/.claude/skills"

  echo

  # `skill-add` shell function: wraps `npx skills add` with the flags this
  # repo requires (see README) so they can't be forgotten on a manual install.
  for rc in "${RC_FILES[@]}"; do
    add_alias_block "$rc"
  done

  echo
  echo "Done. Restart your shell (or re-source your rc file) to use skill-add."
}

do_remove() {
  echo "Removing machine-local symlinks (repo itself is left untouched)."
  echo

  unlink_managed "$REPO_DIR/core" "$HOME/.config/ruler"
  unlink_managed "$REPO_DIR/core/skills" "$HOME/.claude/skills"

  echo
  for rc in "${RC_FILES[@]}"; do
    remove_alias_block "$rc"
  done

  echo
  echo "Done. Repo still at $REPO_DIR — delete it manually if you're done with it."
}

case "$CMD" in
  setup)
    do_setup
    ;;
  remove)
    do_remove
    ;;
  *)
    echo "usage: $(basename "$0") [setup|remove]" >&2
    exit 1
    ;;
esac
