# Project Memory — Save, Update and Prune Automatically

Applies to every project and every session, including subagents' reports that the main session receives.

## Save without asking

Write to the project memory as soon as any of these comes up in the session. Do not ask the user first.

- **Decisions** the user makes: scope, design choices, rules, preferences, what is in or out.
- **Context a later session needs:** what a feature does and why, open work and its resume point, branch and
  PR state, known traps, environment quirks (ports, databases, missing migrations, broken dev accounts).
- **Access details shared for development:** local and dev logins, test accounts, default passwords, local URLs,
  company or tenant ids used for testing. Record which environment they belong to (localhost, dev, staging).
- **Tools and setups** made in the session (MCP servers, scripts, helpers): where they live and how to use them.
- **Corrections** the user gives about how to work, with the reason.

Never save production or live secrets (live API keys, production database passwords, tokens for real
customer data, payment credentials). Note only that they exist and where the user keeps them.

## Read it every session

- At the start of every session, in every project, read MEMORY.md (the index) before planning or answering.
- Open a linked memory file only when its line is relevant to the current task. Never read every file.
- Treat what you read as the starting state: follow recorded decisions, do not re-ask them, and verify any
  file, flag or account a memory names before relying on it.

## Keep it small (memory is loaded into context and costs tokens)

- MEMORY.md: one line per entry, at most 150 characters: `- [Title](file.md) — hook`. Aim for under 30 lines;
  past that, merge related entries or drop stale ones.
- A memory file: at most about 12 lines or 1,000 characters. Facts and pointers, not prose. Use the
  **Why:** / **How to apply:** lines only for feedback and decisions, one line each.
- Point to the long source instead of copying it: spec, ledger, PR, doc link.
- Group a feature's facts in one file instead of many small ones; split only when one part would be read alone.
- When a file grows past the limit, compress it in place: drop history, finished items and anything the
  linked source already says.

## Keep it clean

- One fact per file, short. Specific and useful later; no session narration, no tool output dumps, no
  restating what the code, git history or CLAUDE.md already holds.
- Before writing, check MEMORY.md and the linked files. Update the existing entry instead of adding a duplicate.
- Absolute dates (2026-11-08), not "today" or "last week".

## Maintain every session

- When a memory turns out wrong, fix it in place right away.
- When a memory is outdated (feature shipped, branch merged, decision replaced, account changed, tool removed),
  update it or delete it, and remove its line from MEMORY.md.
- Before relying on a memory that names a file, function, flag or account, check it still holds.
- Keep MEMORY.md to one line per entry and in step with the files.

Reason: the user wants every session to start with the decisions, context and dev access of earlier sessions,
without being asked, and without a memory full of stale or junk entries.
