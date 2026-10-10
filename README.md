# Claude Code — Global Configuration

A complete, reproducible snapshot of my global (user-scope) Claude Code setup: settings, status line,
plugins, MCP servers, skills and global rules.

Point Claude Code at this repository on a fresh machine and it can configure itself without manual
clicking. Everything here is user-scope — it applies to every project on the machine, not just one repo.

**Snapshot taken:** 2026-09-21 on macOS (Darwin 27.0.0), zsh, Claude Code 2.1.278 ·
**Windows support added:** 2026-10-10 on Windows 11 (Git Bash), Claude Code 2.1.292

**Supported platforms:** macOS and Windows 11. Both use the same `settings.json`, rules, skills and
`install.sh`. The installer detects the platform and handles the differences. See the
[Platform guide](#platform-guide) for step-by-step setup on each one.

---

## Quick start

### Option A — let Claude Code do it

Open Claude Code on the new machine and paste:

> Clone `https://github.com/iqbalhasandev/claude-code-config` and follow its README to reproduce this
> global Claude Code configuration on this machine. Follow the Platform guide for this OS, run
> `install.sh`, then tell me what still needs my input (API keys, OAuth logins).

On a machine that is already set up, use [Keeping machines in sync](#keeping-machines-in-sync) instead.

### Option B — run the installer yourself

macOS (Terminal):

```bash
git clone https://github.com/iqbalhasandev/claude-code-config.git
cd claude-code-config
export CONTEXT7_API_KEY="ctx7sk-..."   # optional; skip and Context7 runs on the free tier
./install.sh
```

Windows (Git Bash, not PowerShell or CMD):

```bash
git clone https://github.com/iqbalhasandev/claude-code-config.git
cd claude-code-config
export CONTEXT7_API_KEY="ctx7sk-..."   # optional; skip and Context7 runs on the free tier
./install.sh
```

The installer is idempotent. It backs up any existing `~/.claude/settings.json` and
`~/.claude/statusline-command.sh` to `*.bak.<timestamp>` before overwriting.

### After the installer

Three things need a human, on both platforms:

1. `claude` → `/login` — authenticate the Claude account.
2. `npx ctx7@latest login` — or set `CONTEXT7_API_KEY`, for higher Context7 doc-fetch limits.
3. `claude` → `/design-login` — only if the `claude-design` MCP server is wanted.

---

## Platform guide

### Differences at a glance

| | macOS | Windows 11 |
| --- | --- | --- |
| Shell for `install.sh` and the status line | zsh / bash, built in | Git Bash, from Git for Windows |
| Install Claude Code | `curl -fsSL https://claude.ai/install.sh \| bash` | `irm https://claude.ai/install.ps1 \| iex` in PowerShell |
| Package manager for tools | Homebrew | winget |
| `~/.claude` | `/Users/<you>/.claude` | `C:\Users\<you>\.claude` (`~/.claude` in Git Bash) |
| `date` used by the status line | BSD | GNU — the script handles both |
| Caveman skills | `caveman` plugin, plus `~/.agents/skills` symlinks | `caveman` plugin only; the installer skips the symlinks |
| `markitdown` MCP server | installed with `uv` | optional; added only when `markitdown-mcp` is installed |
| Line endings | LF | LF for `*.sh`, enforced by `.gitattributes` |

### macOS setup

1. Install Claude Code natively (not via npm), so `autoUpdates: false` behaves as intended:

   ```bash
   curl -fsSL https://claude.ai/install.sh | bash
   ```

2. Install the tools:

   ```bash
   brew install node jq gh
   curl -LsSf https://astral.sh/uv/install.sh | sh
   uv tool install markitdown-mcp
   ```

3. Clone the repository and run `./install.sh` (see [Quick start](#option-b--run-the-installer-yourself)).
4. Do the three [after-installer steps](#after-the-installer).

Versions on the macOS source machine:

| Tool | Version | Needed for |
| --- | --- | --- |
| Claude Code | 2.1.278, native install | everything |
| Node.js | 24.18.1 | `npx`-launched MCP servers, `ctx7` CLI |
| npm | 11.16.0 | same |
| `jq` | 1.7.1 | status line (parses the JSON Claude Code pipes in) |
| `awk`, `date` | system BSD versions | status line gauges and reset timestamps |
| `uv` / `uvx` | installed at `~/.local/bin` | `markitdown-mcp` |
| Python | 3.9+ | `markitdown-mcp` |
| `gh` | any recent | optional, for GitHub work |

macOS needs no settings beyond the shared `settings.json`.

### Windows setup

1. Install Git for Windows. It provides Git Bash, which Claude Code's Bash tool, the status line and
   `install.sh` all need:

   ```powershell
   winget install -e --id Git.Git
   ```

2. Install Claude Code natively from PowerShell (no Administrator needed):

   ```powershell
   irm https://claude.ai/install.ps1 | iex
   ```

3. Install the tools:

   ```powershell
   winget install -e --id OpenJS.NodeJS.LTS
   winget install -e --id jqlang.jq
   winget install -e --id GitHub.cli
   ```

   Optional, only if the `markitdown` MCP server is wanted:

   ```powershell
   winget install -e --id astral-sh.uv
   uv tool install markitdown-mcp
   ```

4. Close and reopen the terminal so the new tools are on `PATH`.
5. Open **Git Bash**, clone the repository and run `./install.sh` (see
   [Quick start](#option-b--run-the-installer-yourself)). From PowerShell, run it through Git Bash
   instead:

   ```powershell
   & "C:\Program Files\Git\bin\bash.exe" ./install.sh
   ```

6. Do the three [after-installer steps](#after-the-installer).

Versions on the Windows source machine:

| Tool | Version | Needed for |
| --- | --- | --- |
| Claude Code | 2.1.292, native install | everything |
| Git for Windows (Git Bash) | bash 5.3 | Bash tool, status line, `install.sh` |
| Node.js | 26.9.0 | `npx`-launched MCP servers, `ctx7` CLI |
| npm | 11.19.1 | same |
| `jq` | 1.8.2 | status line |
| `awk`, `date` | GNU, bundled with Git Bash | status line gauges and reset timestamps |
| `gh` | 2.101.0 | optional, for GitHub work |

#### Windows-only settings

The shared `settings.json` works on Windows unchanged. Add these to `~/.claude/settings.json` only on a
Windows machine that needs them. `sync.sh` keeps `CLAUDE_CODE_GIT_BASH_PATH` on the machine: `publish`
never sends it to the repository, and `import` leaves it in place.

- **Claude Code cannot find Git Bash.** Point it at `bash.exe` inside the existing `env` block:

  ```json
  "env": {
    "CLAUDE_CODE_SUBAGENT_MODEL": "sonnet",
    "CLAUDE_CODE_GIT_BASH_PATH": "C:\\Program Files\\Git\\bin\\bash.exe"
  }
  ```

- **`swift-lsp` is not useful without a Swift toolchain.** It is harmless, but it can be turned off by
  setting `"swift-lsp@claude-plugins-official": false` in `enabledPlugins`.

#### Windows troubleshooting

| Symptom | Cause | Fix |
| --- | --- | --- |
| `$'\r': command not found` or `set: pipefail\r: invalid option name` when running `install.sh` | The script was checked out with CRLF line endings | Fresh clones are protected by `.gitattributes`. For an old clone: `sed -i 's/\r$//' install.sh sync.sh statusline-command.sh` |
| Status line is empty | `jq` is missing or not on `PATH` in Git Bash | `winget install -e --id jqlang.jq`, then reopen the terminal |
| `npx`-based MCP server does not start | Native Windows cannot always launch `npx` directly | Re-add it through `cmd`: `claude mcp add --scope user playwright -- cmd /c npx -y @playwright/mcp@latest` |
| `claude: command not found` in Git Bash | `PATH` not refreshed after install | Reopen Git Bash, or run `claude` from PowerShell once |

---

## Keeping machines in sync

Every machine — macOS, Windows or Linux — uses one shared copy of the config below. [`sync.sh`](sync.sh)
moves it between `~/.claude` and this repository. Branches and pull requests move it between machines.
Nothing is ever pushed straight to `main`.

### What is shared and what is not

| Shared on every machine (synced) | Stays on each machine (never synced) |
| --- | --- |
| `settings.json`, except machine-only keys | `env.CLAUDE_CODE_GIT_BASH_PATH` and any key listed in `MACHINE_ONLY_ENV` in `sync.sh` |
| `statusline-command.sh` | `~/.claude.json` — MCP servers, account, OAuth |
| `rules/*.md` | memories, sessions, history, caches |
| `skills/<name>/` — real directories only, not `synced/`, not symlinks | plugin and MCP installs — `install.sh` handles those |

### Commands

Run from the repository root: Terminal on macOS, Git Bash on Windows. All commands need `jq`; `publish`
also needs `gh` logged in (`gh auth login`).

| Command | What it does |
| --- | --- |
| `./sync.sh status` | Lists every shared item as `same`, `differs`, `machine-only` or `repo-only`. Changes nothing. |
| `./sync.sh publish` | Creates branch `sync/<platform>-<timestamp>` from `origin/main`, exports this machine's config, commits, pushes and opens a PR. Deletes the branch again if nothing changed. |
| `./sync.sh import` | Copies the repo config into `~/.claude`. Backs up `settings.json`, `statusline-command.sh` and changed rules to `*.bak.<timestamp>` first. Keeps machine-only keys. |
| `./sync.sh export` | Copies `~/.claude` into the repo working tree only — no branch, commit or PR. |
| `--prune` | With `publish` or `export`: also deletes repo rules and skills that are missing on this machine. Without it they are kept. |

### This machine has new rules, settings or skills — publish them

Use this after adding a rule, changing `settings.json` or editing a local skill on any machine:

```bash
cd claude-code-config
git switch main && git pull
./sync.sh status        # check what differs before publishing
./sync.sh publish       # new branch + commit + push + PR; prints the PR link
```

Then review and merge the PR on GitHub.

`publish` stops without changing anything when:

- the repository has uncommitted changes — commit or stash them first;
- `settings.json` has an `env` key that looks like a secret (`KEY`, `TOKEN`, `SECRET`, `PASSWORD`,
  `CREDENTIAL`). This repository is public. Move the secret out of `settings.json`, or add the key to
  `MACHINE_ONLY_ENV` in `sync.sh` if it must stay local.

The same steps by hand:

```bash
git switch main && git pull
git switch -c sync/<platform>-<date>
./sync.sh export
git diff                                    # review every change
git add -A && git commit -m "Sync global config from <platform>"
git push -u origin HEAD
gh pr create --base main --fill
```

### Another machine published — import its changes

After a sync PR is merged, on every other machine:

```bash
cd claude-code-config
git switch main && git pull
./sync.sh import
```

Restart Claude Code so it reloads settings and rules. `import` never deletes a rule that exists only on
this machine; it warns instead, so that rule can be published or removed on purpose.

### New plugins or MCP servers

These are not file-synced. When adding or removing one:

1. Run `./sync.sh publish` as usual — this records the `enabledPlugins` change in `settings.json`.
2. On the same `sync/...` branch, update `PLUGINS` or the `add_mcp` lines in `install.sh`, and sections
   [3](#3-plugins) or [4](#4-mcp-servers) of this README. Commit and push; the open PR updates.
3. After merge, other machines run `git pull && ./install.sh`. It is idempotent.

### Reading `status` and fixing differences

| Label | Meaning | Usual fix |
| --- | --- | --- |
| `same` | Identical on both sides | Nothing |
| `differs` | Both sides have it, contents differ | Publish if this machine's copy is newer; import if the repo's copy is newer. Unsure which is newer: compare with `git diff --no-index` and merge by hand |
| `machine-only` | Only in `~/.claude` | Publish to share it, or delete it locally if another machine removed it on purpose |
| `repo-only` | Only in the repository | Import to get it, or `publish --prune` to delete it from the repository |

Before changing global config on a machine, start with `git pull && ./sync.sh import`. Then every
machine edits the latest version, and two sync PRs rarely conflict.

### Letting Claude Code do the sync

Open Claude Code in this repository and say **"sync my global config"**. [`CLAUDE.md`](CLAUDE.md) gives
Claude the exact procedure. Whenever a step is unclear — which side of a `differs` item is newer, a
deletion, a secret-looking key, a conflict — Claude must stop and ask with its question tool: four
options, recommended option first and marked **(Recommended)**.

---

## 1. Global settings — `~/.claude/settings.json`

The full file lives in [`settings.json`](settings.json). What each key does:

### Model and reasoning

```json
"model": "opus[1m]",
"effortLevel": "high",
"modelSettings": {
  "claude-opus-5": { "effortLevel": "xhigh" },
  "claude-opus-5-5": { "effortLevel": "xhigh" }
}
```

Default model is Opus with the 1M-token context window. Baseline reasoning effort is `high`; when the
session is actually on Opus 5 or Opus 5.5 it is raised to `xhigh`. The per-model blocks
override the global `effortLevel`, so changing `effortLevel` alone will not affect those sessions.

### Subagent model

```json
"env": { "CLAUDE_CODE_SUBAGENT_MODEL": "sonnet" }
```

Subagents run on Sonnet unless a launch names a model explicitly. This pairs with
[`rules/subagent-models.md`](rules/subagent-models.md), which tells Claude when to override it with Opus.

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

### Notifications

```json
"agentPushNotifEnabled": true
```

Lets agent sessions send push notifications.

### Permissions

```json
"permissions": { "defaultMode": "bypassPermissions" },
"skipDangerousModePermissionPrompt": true
```

Every session starts in bypass-permissions mode, so tool calls run without approval prompts, and the
confirmation dialog for entering that mode is suppressed. Both remove safety prompts — only keep them on
a machine where that trade-off is acceptable.

### Commit attribution

```json
"attribution": { "commit": "", "pr": "", "sessionUrl": false }
```

Empty strings disable the "Generated with Claude Code" trailer on commits and the equivalent line on
pull requests. `sessionUrl: false` also leaves the Claude Code session link out of that text.

### Workflow usage warning

```json
"skipWorkflowUsageWarning": true
```

Skips the usage warning shown before a multi-agent workflow starts.

### Plugins and marketplaces

`enabledPlugins` and `extraKnownMarketplaces` are documented in [section 3](#3-plugins). Both
marketplaces (`claude-plugins-official` and `caveman`) are declared in `extraKnownMarketplaces`.

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

Hard dependencies: `jq` for parsing, `awk` for the number formatting and gauge loops, and `date` for the
reset timestamps. The script works on macOS, Linux and Windows (Git Bash):

- Reset timestamps try GNU `date -d @<epoch>` first, then fall back to BSD `date -r <epoch>`.
- The `jq` output is piped through `tr -d '\r'`, because the Windows `jq` build ends lines with CRLF. A
  trailing `\r` on the last field would otherwise break the `7d` reset timestamp.

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
| `superpowers` | official | 6.4.1 | Process skills: brainstorming, TDD, systematic debugging, writing/executing plans, code review, git worktrees |
| `frontend-design` | official | `b860d6f2` | Visual design guidance for new or reshaped UI |
| `context7` | official | `b860d6f2` | Context7 MCP server + doc-lookup skill |
| `playwright` | official | `b860d6f2` | Playwright browser-automation MCP server |
| `chrome-devtools-mcp` | official | 1.9.0 | Chrome DevTools MCP: performance traces, network, a11y, memory, cookies |
| `claude-code-setup` | official | 1.0.0 | Automation recommender — suggests hooks/subagents/skills for a codebase |
| `playground` | official | `b860d6f2` | Builds interactive single-file HTML playgrounds |
| `swift-lsp` | official | 1.0.0 | Swift language server integration |
| `caveman` | caveman | 2.7.0 | Compressed-output mode, cavecrew subagents, workflow skills, Caveman Cloud cost tooling |

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

### Plugins synced from claude.ai

Four more plugins load automatically from the Claude account after `/login`, under
`~/.claude/plugins/synced/`. They are not installed by `install.sh` and do not appear in `enabledPlugins`:

| Plugin | Version | What it adds |
| --- | --- | --- |
| `design` | 1.2.0 | Design critique, accessibility review, design-system, UX copy, handoff and user-research skills |
| `product-management` | 1.2.0 | Specs, roadmaps, sprint planning, stakeholder updates, research synthesis, competitive briefs |
| `engineering` | 1.2.0 | Code review, architecture/ADRs, system design, debugging, incident response, testing strategy, docs |
| `data` | 1.1.0 | SQL, data exploration, statistics, visualisation, dashboards, analysis validation |

Several of them ship MCP connectors (Figma, Linear, Notion, Slack, Datadog, Amplitude and others) that
stay unauthenticated until each one is connected.

### Note on the caveman plugin

It registers a `SessionStart` hook that injects a persistent "caveman mode" instruction into every
session — terse, compressed assistant output. It is on by default at level `full`. Turn it off per
session with `/caveman off`, or drop the plugin if that style is unwanted. No hook is defined in
`settings.json` itself; the hook is entirely the plugin's.

---

## 4. MCP servers

Five servers at user scope on macOS; four on Windows, where `markitdown` is optional. Stored in
`~/.claude.json` under `mcpServers`, not in `settings.json`.

| Name | Transport | Endpoint / command | Auth |
| --- | --- | --- | --- |
| `context7` | http | `https://mcp.context7.com/mcp` | `Authorization: Bearer <CONTEXT7_API_KEY>` |
| `playwright` | stdio | `npx -y @playwright/mcp@latest` | none |
| `sequential-thinking` | stdio | `npx @modelcontextprotocol/server-sequential-thinking` | none |
| `markitdown` | stdio | `~/.local/bin/markitdown-mcp` (macOS; optional on Windows) | none |
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
| [`rules/model-usage.md`](rules/model-usage.md) | Hard model and effort limits for every session. Never runs any Fable model (main session, subagent, workflow or `model` override), never runs Opus at ultra or max effort, and never starts ultracode or multi-agent "ultra" runs. If a task seems to need one, Claude stops and asks first, naming the model or effort level and why; a "no" holds for the rest of that work. Agents default to Opus or Sonnet at normal effort, Haiku for cheap mechanical work. |
| [`rules/test-runs.md`](rules/test-runs.md) | Test-run discipline for every framework (Jest, Vitest, PHPUnit/Pest, pytest, Go, RSpec, Cargo and others). While implementing, only the test files or cases the change touches run, named explicitly and in single-process / no-watch mode. The full suite runs exactly once, as the final verification step, and every failure in it is reported by name, including failures the change did not cause. |
| [`rules/subagent-models.md`](rules/subagent-models.md) | Model routing for every subagent launch (Agent tool, workflows, parallel batches). Sonnet is the default for implementation, search, tests, docs and mockups; Opus is reserved for reviews and work Sonnet cannot do reliably (architecture, cross-cutting refactors, unclear-cause debugging, money-safety or security reasoning, consistency passes). Every Sonnet subagent gets a complete nine-part brief (goal and done criteria, context, scope, read-first paths, applicable rules, pattern to copy, method with a verify loop, known traps, report format), and user-facing, money-related or cross-cutting Sonnet output goes through an Opus review before it counts as finished. |

To add a rule: drop another `.md` in `~/.claude/rules/`. No registration needed. Then run
`./sync.sh publish` to share it with every other machine.

---

## 6. Skills

Three separate sources feed the skill list.

### a. Caveman skills

The `caveman` plugin ships the caveman skill set on both platforms, namespaced as `caveman:<name>`:

`cavecrew`, `caveman`, `caveman-commit`, `caveman-compress`, `caveman-discover`,
`caveman-evidence-review`, `caveman-explore`, `caveman-help`, `caveman-init`, `caveman-learn`,
`caveman-manage`, `caveman-optimize`, `caveman-review`, `caveman-setup`, `caveman-stats`,
`investigate-first`, `lean-build`, `migration`, `safe-refactor`, `surgical-patch`, `verify-and-stop`

**macOS** also has the same skills un-namespaced, installed from `JuliusBrussee/caveman` into
`~/.agents/skills` and tracked in `~/.agents/.skill-lock.json`. Each entry in `~/.claude/skills/` is a
symlink to `~/.agents/skills/<name>`. `~/.agents/skills` also holds `compress`, `find-skills` and
`context7-mcp`, which are **not** symlinked into `~/.claude/skills` and therefore not active.
`install.sh` recreates this on macOS and Linux.

**Windows** uses the plugin copies only. `install.sh` skips the `~/.agents/skills` clone and symlinks
there, because the plugin already provides every skill and symlinks need Developer Mode on Windows.

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

`~/.claude/skills/synced/<account-id>/` is populated automatically from the Claude account after
`/login` — no manual step. On this machine it carries: `docs`, `docx`, `google-workspace`, `pdf`, `pptx`,
`xlsx`, `morning`, `import-memory`, `skill-creator`, `prompt-master`. Do not copy this directory between
machines; let it re-sync.

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
| `~/.claude/skills/synced/`, `~/.claude/plugins/synced/` | Re-synced from the Claude account on login. |
| `~/.claude/remote-settings.json`, `policy-limits.json` | Server-issued. Refetched. |

---

## 9. Verification

After `install.sh` and `/login`:

```bash
claude --version                       # 2.1.292 or newer
claude plugin list                     # 9 installed plugins enabled, plus 4 synced from claude.ai
claude mcp list                        # macOS: 5 servers; Windows: 4 (+ markitdown if installed)
ls -l ~/.claude/rules/                 # code-comments.md, context7.md, model-usage.md,
                                       # subagent-models.md, test-runs.md
ls -l ~/.claude/skills/                # find-docs, context7-mcp, synced/ (+ caveman symlinks on macOS)
test -x ~/.claude/statusline-command.sh && echo "statusline ok"
./sync.sh status                       # every item: same
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
│   ├── context7.md
│   ├── model-usage.md
│   ├── subagent-models.md
│   └── test-runs.md
├── skills/                    # local skills (this repo: skills/) + synced/ + macOS symlinks
├── plugins/
│   ├── installed_plugins.json
│   ├── known_marketplaces.json
│   ├── cache/                 # plugin payloads
│   └── synced/                # plugins synced from claude.ai
└── projects/<slug>/memory/    # per-project memory files

~/.agents/                     # macOS only
├── .skill-lock.json           # provenance for github-sourced skills
└── skills/

~/.claude.json                 # account state + mcpServers (secrets live here)
```

---

## License

[MIT](LICENSE) © Iqbal Hasan
