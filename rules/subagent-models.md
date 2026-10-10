# Subagents — Sonnet by Default, Opus for Review and Hard Work

Applies to every project and every subagent launch (Agent tool, workflows, parallel batches).

## Which model

- **Default: Sonnet** (`model: "sonnet"`) for every subagent: implementation, building, mechanical edits,
  searching and mapping code, running tests, writing docs, building mockups.
- **Opus** (`model: "opus"`) only for:
  - **Reviews:** code review, design review, spec or plan review, checking another agent's work.
  - **Complex work Sonnet cannot do reliably:** architecture and design decisions, cross-cutting refactors
    over many modules, debugging with an unclear cause, money-safety or security reasoning, consistency passes
    across several screens or files.
- Unsure: start on Sonnet. Escalate to Opus when the Sonnet result fails review or the task turns out complex.
  State in one line why a launch uses Opus.
- Opus unavailable (limit or error): continue on Sonnet with a stronger brief and tell the user.

## Every Sonnet subagent gets a complete brief

A subagent starts with no context. The brief gives it everything it needs to deliver the full outcome without
guessing. Every brief contains:

1. **Goal and done criteria:** the outcome, and the exact check that proves it (command that must pass,
   screenshot to read back, output expected).
2. **Context:** why the work exists, decisions already made and where they are written, what the user said
   that matters, constraints.
3. **Scope:** the files and folders it may touch, what it must never touch, no git unless the user asked.
4. **Read first:** absolute paths in order, with line ranges for large files.
5. **Rules that apply:** which CLAUDE.md sections, global rules and skills to load (comments, i18n, naming,
   tests, frontend).
6. **Pattern to copy:** a reference file that already does it right.
7. **Method:** the steps, including a verify loop (build, test, screenshot and read back) repeated until clean.
8. **Known traps:** anything learned earlier in the session (tool quirks, kit bugs, data contradictions).
9. **Report format:** concise; files changed; verification output; conflicts found and how they were resolved;
   open questions.

- When several agents work in parallel, put the shared rules in one brief file that all of them read, so their
  results stay consistent.
- A task that an earlier agent left half done is briefed as "inspect the current state, finish what is left,
  do not redo finished work".
- After a Sonnet agent reports, check the report against the done criteria. Send user-facing, money-related or
  cross-cutting work to an Opus review before calling it finished.
