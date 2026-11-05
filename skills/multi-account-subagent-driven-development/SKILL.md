---
name: multi-account-subagent-driven-development
description: Execute a Superpowers implementation plan where each task is implemented by a second Claude account (worker-task / claude-b) and reviewed by this native Opus session. Use ONLY when the user explicitly asks to implement with the second account, worker account, claude-b, or this skill by name; otherwise use superpowers:subagent-driven-development as normal.
---

# Multi-Account Subagent-Driven Development

Same loop as `superpowers:subagent-driven-development`, with one change:
**implementers run out-of-process on worker accounts via `worker-task`; reviewers stay in this session (account A, Opus).**

You are the controller. You never write implementation code yourself unless escalating (step 6).

## Setup (once per plan)
1. Use `superpowers:using-git-worktrees` — work on an isolated branch/worktree.
2. Read the plan file. Create a TodoWrite list with one item per task.
3. Locate Superpowers' prompt templates and read them:
   `Glob ~/.claude/plugins/**/subagent-driven-development/*-prompt.md`
   Reuse `implementer-prompt.md` for briefs and the reviewer template(s) for reviews.

## Per task — strictly sequential (never two workers in the same worktree)

1. **Write the brief** to `.worker-runs/task-<N>.md`, based on `implementer-prompt.md`.
   It must be self-contained (the worker cannot see this conversation):
   - The full task text from the plan, verbatim (exact file paths, code, commands).
   - Relevant context: architecture notes, conventions, neighbouring files to read.
   - Follow TDD (`superpowers:test-driven-development` is available to the worker), run the tests,
     commit with a clear message, do NOT push.
   - Report: what was done, test command + result, files changed, open questions.
     If blocked or the spec is ambiguous, stop and say so.

2. **Dispatch**: run `worker-task .worker-runs/task-<N>.md` with Bash
   (`run_in_background: true` for long tasks, then wait; otherwise timeout 600000).
   Optional second arg sets the worker model (e.g. `opus` for a hard task).
   The output names the WORKER account used; `LIMIT_HIT=` lines mean an account ran out and the next took over.

3. **Worker asked a question / blocked**: answer from the plan or ask the user,
   append the answer to the brief, re-dispatch.

4. **Review — never trust the worker's report.** Using BASE_SHA and HEAD_SHA from the output:
   a. Spec compliance: dispatch a native reviewer subagent (spec reviewer template) with the task text and
      `git diff BASE_SHA..HEAD_SHA`. It must read the actual code and run the tests.
   b. Only if spec passes: code quality review (`superpowers:requesting-code-review`) on the same range.
   Reviewers run in this session's account. Never send reviews to a worker account.

5. **Review fails**: write `.worker-runs/task-<N>-fix-<k>.md` with the original task, the reviewer's
   findings verbatim (file:line), and "fix only these issues, re-run tests, commit".
   Dispatch again, re-review. Max 3 fix rounds.

6. **Escalate** after 3 failed rounds, repeated worker errors (EXIT≠0, no JSON), or when every worker
   account is out of limits: tell the user, then fix natively, wait for the reset, or retry with `opus`.

7. **Mark the task complete** only when both reviews approve. Then next task.

## After all tasks
- Final whole-branch review (native) over `git diff <plan-base>..HEAD`.
- `superpowers:finishing-a-development-branch`.
- Short summary: tasks done, worker account per task, fix rounds, escalations.

## Red flags
- Implementing code yourself instead of dispatching (except escalation).
- Accepting a task because the worker *says* tests pass — reviewers must run them.
- Running multiple workers concurrently in one worktree.
- Putting secrets or `.env` contents into briefs.