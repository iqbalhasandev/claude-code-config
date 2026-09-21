# Claude Code — Global Configuration

A complete, reproducible snapshot of my global (user-scope) Claude Code setup: settings, status line,
plugins, MCP servers, skills and global rules.

Point Claude Code at this repository on a fresh machine and it can configure itself without manual
clicking. Everything here is user-scope — it applies to every project on the machine, not just one repo.

**Snapshot taken:** 2026-09-21 · **Claude Code:** 2.1.278 · **Platform:** macOS (Darwin 27.0.0), zsh

---

## Quick start

### Option A — let Claude Code do it

Open Claude Code on the new machine and paste:

> Clone `https://github.com/iqbalhasandev/claude-code-config` and follow its README to reproduce this
> global Claude Code configuration on this machine. Run `install.sh`, then tell me what still needs my
> input (API keys, OAuth logins).

### Option B — run the installer yourself

```bash
git clone https://github.com/iqbalhasandev/claude-code-config.git
cd claude-code-config
export CONTEXT7_API_KEY="ctx7sk-..."   # optional; skip and Context7 runs on the free tier
./install.sh
```

The installer is idempotent. It backs up any existing `~/.claude/settings.json` and
`~/.claude/statusline-command.sh` to `*.bak.<timestamp>` before overwriting.

### After the installer

Three things need a human:

1. `claude` → `/login` — authenticate the Claude account.
2. `npx ctx7@latest login` — or set `CONTEXT7_API_KEY`, for higher Context7 doc-fetch limits.
3. `claude` → `/design-login` — only if the `claude-design` MCP server is wanted.

---

## Prerequisites

| Tool | Version on the source machine | Needed for |
| --- | --- | --- |
| Claude Code | 2.1.278, native install | everything |
| Node.js | 24.18.1 | `npx`-launched MCP servers, `ctx7` CLI |
| npm | 11.16.0 | same |
| `jq` | 1.7.1 | status line (parses the JSON Claude Code pipes in) |
| `awk`, `date` | system BSD versions | status line gauges and reset timestamps |
| `uv` / `uvx` | installed at `~/.local/bin` | `markitdown-mcp` |
| Python | 3.9+ | `markitdown-mcp` |
| `gh` | any recent | optional, for GitHub work |

Install Claude Code natively (not via npm) so `autoUpdates: false` behaves as intended:

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

`jq` and `uv` on macOS:

```bash
brew install jq
curl -LsSf https://astral.sh/uv/install.sh | sh
uv tool install markitdown-mcp
```

---

## 1. Global settings — `~/.claude/settings.json`

The full file lives in [`settings.json`](settings.json). What each key does:

### Model and reasoning

```json
"model": "opus[1m]",
"effortLevel": "high",
"modelSettings": { "claude-opus-5": { "effortLevel": "xhigh" } }
```

Default model is Opus with the 1M-token context window. Baseline reasoning effort is `high`; when the
session is actually on Opus 5 it is raised to `xhigh`. The per-model block overrides the global
`effortLevel`, so changing `effortLevel` alone will not affect Opus 5 sessions.

### Appearance

```json
"theme": "dark-daltonized"
```

Dark theme with a colour-blind-safe palette. The same value is mirrored into `~/.claude.json` by the
app itself on first run — it does not need to be set there by hand.

### Status line

```json
"statusLine": { "type": "command", "command": "bash \"$HOME/.claude/statusline-command.sh\"" }
```

See [section 2](#2-status-line--the-gauge-bars).

### Voice input

```json
"voice": { "enabled": true, "mode": "hold" },
"voiceEnabled": true
```

Push-to-talk rather than toggle: hold the key to dictate, release to stop.

### Permissions

```json
"skipDangerousModePermissionPrompt": true
```

Suppresses the confirmation dialog when entering bypass-permissions mode. This removes a safety
prompt — only keep it on a machine where that trade-off is acceptable.

### Commit attribution

```json
"attribution": { "commit": "", "pr": "" }
```

Empty strings disable the "Generated with Claude Code" trailer on commits and the equivalent line on
pull requests.

### Plugins and marketplaces

`enabledPlugins` and `extraKnownMarketplaces` are documented in [section 3](#3-plugins).

---

## 2. Status line — the gauge bars

[`statusline-command.sh`](statusline-command.sh) → installs to `~/.claude/statusline-command.sh`
(must be executable).

Claude Code pipes a JSON blob to the script on stdin on every render; the script prints one ANSI-coloured
line. Output looks like:

```
Opus 5 [xhigh] | $4.21 | ctx ▮▮▮▯▯▯▯▯ 34% | 5h ▮▮▯▯▯ 41% (18:30) | 7d ▮▯▯▯▯ 12% (Sep 28)
```

Segments, left to right, joined by a dim `|`:

| Segment | Source field | Notes |
| --- | --- | --- |
| Model name | `.model.display_name` | dim grey |
| `[effort]` | `.effort.level` | violet, only when present |
| Cost | `.cost.total_cost_usd` | session cost, 2 decimals |
| `ctx` gauge | `.context_window.used_percentage` | 8 cells |
| `5h` gauge | `.rate_limits.five_hour` | 5 cells, reset shown as `HH:MM` |
| `7d` gauge | `.rate_limits.seven_day` | 5 cells, reset shown as `Mon D` |

The gauges are the "highlight bars": `▮` filled, `▯` empty, and the colour is a threshold on the same
percentage — green (256-colour `71`) below 50%, amber (`178`) from 50% to 79%, red (`203`) at 80% and
above. A non-zero percentage always shows at least one filled cell, so a 1% usage never renders as an
empty bar. Rate-limit segments are skipped entirely when the API reports `-1` (unknown).

Hard dependencies: `jq` for parsing, `awk` for the number formatting and gauge loops, and BSD `date -r`
for the reset timestamps. On Linux, `date -r <epoch>` means something different — change those two calls
to `date -d @<epoch>` if this is ever ported.

---

## 3. Plugins

Two marketplaces are registered:

| Marketplace | Source |
| --- | --- |
| `claude-plugins-official` | github: `anthropics/claude-plugins-official` |
| `caveman` | github: `JuliusBrussee/caveman` |

Nine plugins, all installed at **user** scope, all enabled:

| Plugin | Marketplace | Version | What it adds |
| --- | --- | --- | --- |
| `superpowers` | official | 6.3.0 | Process skills: brainstorming, TDD, systematic debugging, writing/executing plans, code review, git worktrees |
| `frontend-design` | official | `c447c320` | Visual design guidance for new or reshaped UI |
| `context7` | official | `c447c320` | Context7 MCP server + doc-lookup skill |
| `playwright` | official | `c447c320` | Playwright browser-automation MCP server |
| `chrome-devtools-mcp` | official | 1.9.0 | Chrome DevTools MCP: performance traces, network, a11y, memory, cookies |
| `claude-code-setup` | official | 1.0.0 | Automation recommender — suggests hooks/subagents/skills for a codebase |
| `playground` | official | `c447c320` | Builds interactive single-file HTML playgrounds |
| `swift-lsp` | official | 1.0.0 | Swift language server integration |
| `caveman` | caveman | `a0109974` | Compressed-output mode, cavecrew subagents, Caveman Cloud cost tooling |

Reinstall:

```bash
claude plugin marketplace add anthropics/claude-plugins-official
claude plugin marketplace add JuliusBrussee/caveman

claude plugin install superpowers@claude-plugins-official
claude plugin install frontend-design@claude-plugins-official
claude plugin install context7@claude-plugins-official
claude plugin install playwright@claude-plugins-official
claude plugin install chrome-devtools-mcp@claude-plugins-official
claude plugin install claude-code-setup@claude-plugins-official
claude plugin install playground@claude-plugins-official
claude plugin install swift-lsp@claude-plugins-official
claude plugin install caveman@caveman
```

`install.sh` does this, then writes the `enabledPlugins` block so the set is enabled without further
prompting.

### Note on the caveman plugin

It registers a `SessionStart` hook that injects a persistent "caveman mode" instruction into every
session — terse, compressed assistant output. It is on by default at level `full`. Turn it off per
session with `/caveman off`, or drop the plugin if that style is unwanted. No hook is defined in
`settings.json` itself; the hook is entirely the plugin's.

---

## 4. MCP servers

Five servers at user scope. Stored in `~/.claude.json` under `mcpServers`, not in `settings.json`.

| Name | Transport | Endpoint / command | Auth |
| --- | --- | --- | --- |
| `context7` | http | `https://mcp.context7.com/mcp` | `Authorization: Bearer <CONTEXT7_API_KEY>` |
| `playwright` | stdio | `npx -y @playwright/mcp@latest` | none |
| `sequential-thinking` | stdio | `npx @modelcontextprotocol/server-sequential-thinking` | none |
| `markitdown` | stdio | `~/.local/bin/markitdown-mcp` | none |
| `claude-design` | http | `https://api.anthropic.com/v1/design/mcp` | Claude account, via `/design-login` |

Reinstall:

```bash
claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp \
  --header "Authorization: Bearer ${CONTEXT7_API_KEY}"

claude mcp add --scope user playwright -- npx -y @playwright/mcp@latest
claude mcp add --scope user sequential-thinking -- npx @modelcontextprotocol/server-sequential-thinking
claude mcp add --scope user markitdown -- "$HOME/.local/bin/markitdown-mcp"
claude mcp add --scope user --transport http claude-design https://api.anthropic.com/v1/design/mcp
```

Verify with `claude mcp list`.

### Secrets

The Context7 key is **not** in this repository. Export `CONTEXT7_API_KEY` before running `install.sh`,
or skip it — Context7 works without a key at a lower rate limit and `npx ctx7@latest login` can add one
later. Every other server is either unauthenticated or uses the Claude account's own OAuth.

### Plugin-provided MCP servers

The `context7`, `playwright` and `chrome-devtools-mcp` plugins each ship their own MCP server, so those
appear twice in a session (once as the user-scope server above, once namespaced as
`plugin_<name>_<server>`). Harmless, but worth knowing before debugging a "duplicate tools" surprise —
removing the user-scope `context7` and `playwright` entries is safe if only the plugin copies are wanted.

---

## 5. Global rules — `~/.claude/rules/`

Every `.md` file in `~/.claude/rules/` is auto-loaded into the system prompt of every session, in every
project. There is no `~/.claude/CLAUDE.md` on this setup — the rules directory carries that role.

| File | Effect |
| --- | --- |
| [`rules/code-comments.md`](rules/code-comments.md) | Minimal-comment policy across every language. Zero inline comments by default; a comment is treated as a defect unless it documents a non-obvious invariant, a specific prevented bug, an external spec reference, a deliberate convention deviation, or unexpressible type info. Caps allowed comments at ~1 per 30 lines, max 2 lines each. Reasoning belongs in commit messages, PRs or `docs/`, never in source. |
| [`rules/context7.md`](rules/context7.md) | Forces the `ctx7` CLI for any library/framework/SDK/API/CLI/cloud-service question, even well-known ones, in preference to web search and to training data. Documents the two-step flow (`ctx7 library <name>` to resolve an `/org/project` id, then `ctx7 docs <id> "<query>"`), one concept per query, max 3 commands per question, and explicitly forbids silently falling back to training data on a quota error. |

To add a rule: drop another `.md` in `~/.claude/rules/`. No registration needed.

---

## 6. Skills

Three separate sources feed the skill list.

### a. `~/.agents/skills` — symlinked into `~/.claude/skills`

Installed from `JuliusBrussee/caveman` and tracked in `~/.agents/.skill-lock.json`. Each entry in
`~/.claude/skills/` is a symlink to `~/.agents/skills/<name>`:

`cavecrew`, `caveman`, `caveman-commit`, `caveman-compress`, `caveman-discover`,
`caveman-evidence-review`, `caveman-explore`, `caveman-help`, `caveman-learn`, `caveman-manage`,
`caveman-optimize`, `caveman-review`, `caveman-setup`, `caveman-stats`, `investigate-first`,
`lean-build`, `migration`, `safe-refactor`, `surgical-patch`, `verify-and-stop`

`~/.agents/skills` also holds `compress`, `find-skills` and `context7-mcp`, which are **not** symlinked
into `~/.claude/skills` and therefore not active.

The workflow skills are the genuinely reusable part of that set — `investigate-first` (evidence-ranked
diagnosis before editing), `lean-build` (scope-bounded feature work), `migration` (reversible
transitions), `safe-refactor` (behaviour-preserving restructuring), `surgical-patch` (narrowest-layer
bug fix), `verify-and-stop` (validation without scope creep).

### b. Local skill directories

Two real directories (not symlinks) in `~/.claude/skills/`, each a single `SKILL.md`:

- `find-docs` — documentation lookup for any library/framework/SDK/CLI/cloud service.
- `context7-mcp` — same intent, routed through the Context7 MCP server instead of the CLI.

Both are in this repo under [`skills/`](skills/) and are copied in by the installer.

### c. Skills synced from claude.ai

`~/.claude/skills/synced/` is populated automatically from the Claude account after `/login` — no manual
step. On this machine it carries: `docs`, `docx`, `pdf`, `pptx`, `xlsx`, `morning`, `import-memory`,
`skill-creator`, `prompt-master`. Do not copy this directory between machines; let it re-sync.

---

## 7. Hooks

None configured in `settings.json`.

The only active hook is the `SessionStart` hook shipped by the `caveman` plugin. If a hook is wanted
later, it goes in `settings.json` under `hooks` — the harness runs it, so it cannot be expressed as a
memory or a rule.

---

## 8. Not in this repository (and why)

| Thing | Why it is excluded |
| --- | --- |
| Context7 API key | Secret. Supply via `CONTEXT7_API_KEY`. |
| `~/.claude.json` in full | Contains OAuth account data, `userID`, `machineID`, telemetry counters, feature-flag caches and per-project history. Only the `mcpServers` subset is reproduced, as commands. |
| `~/.claude/projects/*/memory/` | Per-project memories, machine-local and often private. Rebuild naturally. |
| `~/.claude/history.jsonl`, `sessions/`, `telemetry/`, `shell-snapshots/`, `paste-cache/` | Session state and caches. Regenerated. |
| `~/.claude/plugins/cache/`, `marketplaces/` | Regenerated by `claude plugin install`. |
| `~/.claude/skills/synced/` | Re-synced from the Claude account on login. |
| `~/.claude/remote-settings.json`, `policy-limits.json` | Server-issued. Refetched. |

---

## 9. Verification

After `install.sh` and `/login`:

```bash
claude --version                       # 2.1.278 or newer
claude plugin list                     # 9 plugins, all enabled
claude mcp list                        # 5 servers; claude-design needs /design-login
ls -l ~/.claude/rules/                 # code-comments.md, context7.md
ls -l ~/.claude/skills/                # symlinks + find-docs + context7-mcp
test -x ~/.claude/statusline-command.sh && echo "statusline ok"
```

Then start a session and check that the status line renders gauge bars, and that the model shows as
Opus with `[xhigh]`.

---

## 10. Reference — where each thing lives

```
~/.claude/
├── settings.json              # global settings (this repo: settings.json)
├── statusline-command.sh      # status line renderer (this repo: statusline-command.sh)
├── rules/                     # auto-loaded global instructions (this repo: rules/)
│   ├── code-comments.md
│   └── context7.md
├── skills/                    # symlinks to ~/.agents/skills + local skills + synced/
├── plugins/
│   ├── installed_plugins.json
│   ├── known_marketplaces.json
│   └── cache/                 # plugin payloads
└── projects/<slug>/memory/    # per-project memory files

~/.agents/
├── .skill-lock.json           # provenance for github-sourced skills
└── skills/

~/.claude.json                 # account state + mcpServers (secrets live here)
```

---

## License

[MIT](LICENSE) © Iqbal Hasan
