#!/usr/bin/env bash
# Keep the shared Claude Code config identical on every machine (macOS, Windows, Linux).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
STAMP="$(date +%Y%m%d-%H%M%S)"
MACHINE_ONLY_ENV='["CLAUDE_CODE_GIT_BASH_PATH"]'
SECRET_ENV_PATTERN='KEY|TOKEN|SECRET|PASSWORD|CREDENTIAL'
PRUNE=0

case "$(uname -s)" in
  Darwin)               PLATFORM=macos ;;
  MINGW*|MSYS*|CYGWIN*) PLATFORM=windows ;;
  *)                    PLATFORM=linux ;;
esac

info()  { printf '\033[38;5;71m==>\033[0m %s\n' "$1"; }
warn()  { printf '\033[38;5;178m warn\033[0m %s\n' "$1"; }
fail()  { printf '\033[38;5;203merror\033[0m %s\n' "$1" >&2; exit 1; }

usage() {
  cat <<'EOF'
Usage: ./sync.sh <command>

  status   show which shared files differ between this repo and ~/.claude
  publish  export onto a new branch from origin/main, commit, push and open a PR
  export   copy this machine's ~/.claude into the repo (no git)
  import   copy the repo into this machine's ~/.claude, after git pull

  --prune  with publish or export: also delete repo rules and skills that are missing on
           this machine. Without it, repo-only items are kept.

Shared on every platform: settings.json, statusline-command.sh, rules/*.md, skills/<name>/.
Machine-only settings (env.CLAUDE_CODE_GIT_BASH_PATH) stay on the machine.
EOF
}

shared_settings() {
  jq --argjson machine "$MACHINE_ONLY_ENV" '
    if .env then .env |= with_entries(select(.key | IN($machine[]) | not)) else . end
    | if .env == {} then del(.env) else . end' "$1" | tr -d '\r'
}

merge_machine_settings() {
  local repo_settings=$1 machine_settings=$2
  if [ ! -f "$machine_settings" ]; then
    tr -d '\r' < "$repo_settings"
    return
  fi
  jq -s --argjson machine "$MACHINE_ONLY_ENV" '
    (.[1].env // {} | with_entries(select(.key | IN($machine[])))) as $keep
    | if ($keep | length) > 0 then .[0] * {env: $keep} else .[0] end' \
    "$repo_settings" "$machine_settings" | tr -d '\r'
}

fingerprint() {
  if [ -d "$1" ]; then
    (cd "$1" && find . -type f ! -name .DS_Store | LC_ALL=C sort | while IFS= read -r f; do
      printf '%s\n' "$f"
      tr -d '\r' < "$f"
    done) | cksum
  else
    tr -d '\r' < "$1" | cksum
  fi
}

state() {
  local repo_path=$1 machine_path=$2
  if [ ! -e "$repo_path" ]; then echo machine-only
  elif [ ! -e "$machine_path" ]; then echo repo-only
  elif [ "$(fingerprint "$repo_path")" = "$(fingerprint "$machine_path")" ]; then echo same
  else echo differs
  fi
}

settings_state() {
  if [ ! -f "$CLAUDE_DIR/settings.json" ]; then echo repo-only; return; fi
  if [ "$(jq -S . "$REPO_DIR/settings.json" | tr -d '\r' | cksum)" = \
       "$(shared_settings "$CLAUDE_DIR/settings.json" | jq -S . | tr -d '\r' | cksum)" ]; then
    echo same
  else
    echo differs
  fi
}

machine_skills() {
  local dir
  for dir in "$CLAUDE_DIR"/skills/*/; do
    dir="${dir%/}"
    [ -L "$dir" ] && continue
    [ "$(basename "$dir")" = synced ] && continue
    [ -f "$dir/SKILL.md" ] || continue
    basename "$dir"
  done
}

repo_skills() {
  local dir
  for dir in "$REPO_DIR"/skills/*/; do
    [ -f "$dir/SKILL.md" ] && basename "$dir"
  done
  return 0
}

list_names() {
  local dir=$1 f
  for f in "$dir"/*.md; do
    [ -e "$f" ] && basename "$f"
  done
  return 0
}

cmd_status() {
  local changes=0 name
  row() {
    printf '  %-13s %s\n' "$1" "$2"
    [ "$1" = same ] || changes=$((changes + 1))
  }

  row "$(settings_state)" settings.json
  row "$(state "$REPO_DIR/statusline-command.sh" "$CLAUDE_DIR/statusline-command.sh")" statusline-command.sh
  for name in $( { list_names "$REPO_DIR/rules"; list_names "$CLAUDE_DIR/rules"; } | LC_ALL=C sort -u); do
    row "$(state "$REPO_DIR/rules/$name" "$CLAUDE_DIR/rules/$name")" "rules/$name"
  done
  for name in $( { repo_skills; machine_skills; } | LC_ALL=C sort -u); do
    row "$(state "$REPO_DIR/skills/$name" "$CLAUDE_DIR/skills/$name")" "skills/$name/"
  done

  if [ "$changes" -eq 0 ]; then
    info "in sync"
  else
    info "$changes item(s) out of sync — see \"Reading status\" in README.md, then ./sync.sh publish or ./sync.sh import"
  fi
}

cmd_export() {
  [ -f "$CLAUDE_DIR/settings.json" ] || fail "$CLAUDE_DIR/settings.json not found"
  local name f settings secrets

  settings="$(shared_settings "$CLAUDE_DIR/settings.json")"
  secrets="$(printf '%s' "$settings" | jq -r --arg pattern "$SECRET_ENV_PATTERN" \
    '.env // {} | keys[] | select(test($pattern; "i"))' | tr -d '\r' | tr '\n' ' ')"
  [ -z "$secrets" ] || fail "settings.json env holds secret-looking keys: $secrets— this repo is public. Move them out of settings.json or add them to MACHINE_ONLY_ENV in sync.sh."

  printf '%s\n' "$settings" > "$REPO_DIR/settings.json"
  info "exported settings.json"

  tr -d '\r' < "$CLAUDE_DIR/statusline-command.sh" > "$REPO_DIR/statusline-command.sh"
  info "exported statusline-command.sh"

  mkdir -p "$REPO_DIR/rules"
  for f in "$REPO_DIR"/rules/*.md; do
    [ -e "$f" ] || continue
    [ -e "$CLAUDE_DIR/rules/$(basename "$f")" ] && continue
    if [ "$PRUNE" = 1 ]; then
      rm -f "$f"
      info "pruned rules/$(basename "$f")"
    else
      warn "rules/$(basename "$f") is missing on this machine — kept in the repo (use --prune to delete it)"
    fi
  done
  for f in "$CLAUDE_DIR"/rules/*.md; do
    [ -e "$f" ] || continue
    tr -d '\r' < "$f" > "$REPO_DIR/rules/$(basename "$f")"
  done
  info "exported rules: $(list_names "$REPO_DIR/rules" | tr '\n' ' ')"

  mkdir -p "$REPO_DIR/skills"
  for name in $(repo_skills); do
    [ -d "$CLAUDE_DIR/skills/$name" ] && continue
    if [ "$PRUNE" = 1 ]; then
      rm -rf "${REPO_DIR:?}/skills/$name"
      info "pruned skills/$name/"
    else
      warn "skills/$name/ is missing on this machine — kept in the repo (use --prune to delete it)"
    fi
  done
  for name in $(machine_skills); do
    rm -rf "${REPO_DIR:?}/skills/$name"
    cp -R "$CLAUDE_DIR/skills/$name" "$REPO_DIR/skills/$name"
  done
  info "exported skills: $(repo_skills | tr '\n' ' ')"

  info "review with: git status && git diff — or use ./sync.sh publish to branch, commit and open a PR"
}

cmd_publish() {
  command -v git >/dev/null || fail "git is required"
  command -v gh  >/dev/null || fail "gh is required to open the PR. macOS: brew install gh · Windows: winget install -e --id GitHub.cli"
  cd "$REPO_DIR"

  [ -z "$(git status --porcelain)" ] || fail "the repo has uncommitted changes — commit or stash them first"

  local branch changes title
  branch="sync/$PLATFORM-$STAMP"
  git fetch -q origin main
  git switch -q -c "$branch" origin/main
  info "created branch $branch from origin/main"

  cmd_export
  git add -A
  if git diff --cached --quiet; then
    git switch -q -
    git branch -q -D "$branch"
    info "nothing to publish — the repo already matches this machine"
    return
  fi

  changes="$(git diff --cached --name-status)"
  title="Sync global config from $PLATFORM"
  git commit -q -m "$title" -m "$changes"
  git push -q -u origin "$branch"
  info "pushed $branch"

  gh pr create --base main --head "$branch" --title "$title" --body "$(printf '%s\n' \
    "## Summary" "" \
    "Exported from a $PLATFORM machine with \`./sync.sh publish\`." "" \
    "Changed files (git name-status):" "" \
    '```' "$changes" '```' "" \
    "## After merge" "" \
    "On every other machine: \`git switch main && git pull && ./sync.sh import\`, then restart Claude Code.")"
}

cmd_import() {
  local name f tmp
  mkdir -p "$CLAUDE_DIR/rules" "$CLAUDE_DIR/skills"

  if [ "$(settings_state)" != same ]; then
    tmp="$(mktemp)"
    merge_machine_settings "$REPO_DIR/settings.json" "$CLAUDE_DIR/settings.json" > "$tmp"
    if [ -f "$CLAUDE_DIR/settings.json" ]; then
      cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.bak.$STAMP"
      info "backed up settings.json -> settings.json.bak.$STAMP"
    fi
    mv "$tmp" "$CLAUDE_DIR/settings.json"
    info "imported settings.json"
  fi

  if [ "$(state "$REPO_DIR/statusline-command.sh" "$CLAUDE_DIR/statusline-command.sh")" != same ]; then
    if [ -f "$CLAUDE_DIR/statusline-command.sh" ]; then
      cp "$CLAUDE_DIR/statusline-command.sh" "$CLAUDE_DIR/statusline-command.sh.bak.$STAMP"
      info "backed up statusline-command.sh -> statusline-command.sh.bak.$STAMP"
    fi
    tr -d '\r' < "$REPO_DIR/statusline-command.sh" > "$CLAUDE_DIR/statusline-command.sh"
    info "imported statusline-command.sh"
  fi
  chmod +x "$CLAUDE_DIR/statusline-command.sh"

  for f in "$REPO_DIR"/rules/*.md; do
    [ -e "$f" ] || continue
    name="$(basename "$f")"
    if [ "$(state "$f" "$CLAUDE_DIR/rules/$name")" = differs ]; then
      cp "$CLAUDE_DIR/rules/$name" "$CLAUDE_DIR/rules/$name.bak.$STAMP"
      info "backed up rules/$name -> rules/$name.bak.$STAMP"
    fi
    cp "$f" "$CLAUDE_DIR/rules/$name"
  done
  info "imported rules: $(list_names "$REPO_DIR/rules" | tr '\n' ' ')"
  for f in "$CLAUDE_DIR"/rules/*.md; do
    [ -e "$f" ] || continue
    [ -e "$REPO_DIR/rules/$(basename "$f")" ] || warn "rules/$(basename "$f") exists only on this machine — export it or delete it"
  done

  for name in $(repo_skills); do
    rm -rf "${CLAUDE_DIR:?}/skills/$name"
    cp -R "$REPO_DIR/skills/$name" "$CLAUDE_DIR/skills/$name"
  done
  info "imported skills: $(repo_skills | tr '\n' ' ')"
}

command -v jq >/dev/null || fail "jq is required. macOS: brew install jq · Windows: winget install -e --id jqlang.jq"

COMMAND="${1:-}"
[ "${2:-}" = --prune ] && PRUNE=1

case "$COMMAND" in
  status)  cmd_status ;;
  publish) cmd_publish ;;
  export)  cmd_export ;;
  import)  cmd_import ;;
  *)       usage; exit 1 ;;
esac
