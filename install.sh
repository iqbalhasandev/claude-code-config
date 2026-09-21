#!/usr/bin/env bash
# Reproduce the global Claude Code configuration described in README.md.
# Idempotent: existing settings.json and statusline-command.sh are backed up before being replaced.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
STAMP="$(date +%Y%m%d-%H%M%S)"

info()  { printf '\033[38;5;71m==>\033[0m %s\n' "$1"; }
warn()  { printf '\033[38;5;178m warn\033[0m %s\n' "$1"; }
fail()  { printf '\033[38;5;203merror\033[0m %s\n' "$1" >&2; exit 1; }

backup() {
  [ -e "$1" ] || return 0
  cp -R "$1" "$1.bak.$STAMP"
  info "backed up $1 -> $1.bak.$STAMP"
}

# ---------------------------------------------------------------- prerequisites

command -v claude >/dev/null || fail "claude not found. Install: curl -fsSL https://claude.ai/install.sh | bash"
command -v node   >/dev/null || fail "node not found. Install Node 20+ (24.x recommended)."
command -v npx    >/dev/null || fail "npx not found (ships with npm)."
command -v jq     >/dev/null || warn "jq not found — the status line will render empty. brew install jq"

info "claude $(claude --version 2>/dev/null | head -1)"

mkdir -p "$CLAUDE_DIR/rules" "$CLAUDE_DIR/skills"

# ---------------------------------------------------------------------- settings

backup "$CLAUDE_DIR/settings.json"
cp "$REPO_DIR/settings.json" "$CLAUDE_DIR/settings.json"
info "installed settings.json"

backup "$CLAUDE_DIR/statusline-command.sh"
cp "$REPO_DIR/statusline-command.sh" "$CLAUDE_DIR/statusline-command.sh"
chmod +x "$CLAUDE_DIR/statusline-command.sh"
info "installed statusline-command.sh"

# ------------------------------------------------------------------------- rules

cp "$REPO_DIR"/rules/*.md "$CLAUDE_DIR/rules/"
info "installed rules: $(ls "$REPO_DIR"/rules | tr '\n' ' ')"

# ------------------------------------------------------------------ local skills

for skill in "$REPO_DIR"/skills/*/; do
  name="$(basename "$skill")"
  rm -rf "$CLAUDE_DIR/skills/$name"
  cp -R "$skill" "$CLAUDE_DIR/skills/$name"
  info "installed skill: $name"
done

# ------------------------------------------------------------- caveman skill set

if [ -d "$HOME/.agents/skills" ]; then
  info "~/.agents/skills already present — skipping clone"
else
  info "installing caveman skills into ~/.agents/skills"
  tmp="$(mktemp -d)"
  if git clone --depth 1 https://github.com/JuliusBrussee/caveman.git "$tmp/caveman" >/dev/null 2>&1; then
    mkdir -p "$HOME/.agents/skills"
    cp -R "$tmp/caveman/skills/." "$HOME/.agents/skills/"
    rm -rf "$tmp"
  else
    warn "could not clone JuliusBrussee/caveman — skipping the ~/.agents/skills set"
  fi
fi

CAVEMAN_SKILLS=(
  cavecrew caveman caveman-commit caveman-compress caveman-discover
  caveman-evidence-review caveman-explore caveman-help caveman-learn
  caveman-manage caveman-optimize caveman-review caveman-setup caveman-stats
  investigate-first lean-build migration safe-refactor surgical-patch verify-and-stop
)
for name in "${CAVEMAN_SKILLS[@]}"; do
  src="$HOME/.agents/skills/$name"
  [ -d "$src" ] || continue
  ln -sfn "../../.agents/skills/$name" "$CLAUDE_DIR/skills/$name"
done
info "linked ${#CAVEMAN_SKILLS[@]} skills from ~/.agents/skills"

# --------------------------------------------------------------------- plugins

info "adding marketplaces"
claude plugin marketplace add anthropics/claude-plugins-official >/dev/null 2>&1 || warn "official marketplace already present"
claude plugin marketplace add JuliusBrussee/caveman              >/dev/null 2>&1 || warn "caveman marketplace already present"

PLUGINS=(
  superpowers@claude-plugins-official
  frontend-design@claude-plugins-official
  context7@claude-plugins-official
  playwright@claude-plugins-official
  chrome-devtools-mcp@claude-plugins-official
  claude-code-setup@claude-plugins-official
  playground@claude-plugins-official
  swift-lsp@claude-plugins-official
  caveman@caveman
)
for plugin in "${PLUGINS[@]}"; do
  if claude plugin install "$plugin" >/dev/null 2>&1; then
    info "installed plugin: $plugin"
  else
    warn "plugin install skipped or already present: $plugin"
  fi
done

# ------------------------------------------------------------------ MCP servers

add_mcp() {
  local name="$1"; shift
  if claude mcp get "$name" >/dev/null 2>&1; then
    info "mcp already configured: $name"
    return 0
  fi
  if claude mcp add "$@" >/dev/null 2>&1; then
    info "added mcp: $name"
  else
    warn "could not add mcp: $name"
  fi
}

if [ -n "${CONTEXT7_API_KEY:-}" ]; then
  add_mcp context7 --scope user --transport http context7 https://mcp.context7.com/mcp \
    --header "Authorization: Bearer ${CONTEXT7_API_KEY}"
else
  add_mcp context7 --scope user --transport http context7 https://mcp.context7.com/mcp
  warn "CONTEXT7_API_KEY not set — context7 added without a key (free tier). Run: npx ctx7@latest login"
fi

add_mcp playwright --scope user playwright -- npx -y @playwright/mcp@latest
add_mcp sequential-thinking --scope user sequential-thinking -- npx @modelcontextprotocol/server-sequential-thinking
add_mcp claude-design --scope user --transport http claude-design https://api.anthropic.com/v1/design/mcp

if [ -x "$HOME/.local/bin/markitdown-mcp" ]; then
  add_mcp markitdown --scope user markitdown -- "$HOME/.local/bin/markitdown-mcp"
else
  warn "markitdown-mcp not found. Install it, then rerun: uv tool install markitdown-mcp"
fi

# ------------------------------------------------------------------------- done

cat <<'EOF'

Done. Three steps still need you:

  1. claude  ->  /login              authenticate the Claude account (also syncs claude.ai skills)
  2. npx ctx7@latest login           higher Context7 limits (or export CONTEXT7_API_KEY and rerun)
  3. claude  ->  /design-login       only if the claude-design MCP server is wanted

Verify:

  claude plugin list
  claude mcp list
  ls -l ~/.claude/rules ~/.claude/skills

EOF
