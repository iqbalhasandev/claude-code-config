---
name: omni-subagent-driven-development
description: Execute a Superpowers implementation plan where each task is implemented by an OmniRoute-backed headless worker (omni-task) and reviewed by native Claude Opus before moving on. Use instead of superpowers:subagent-driven-development unless the user says "native".
---

# Omni Subagent-Driven Development

Same loop as superpowers:subagent-driven-development, with one change:
implementers run out-of-process on OmniRoute via omni-task; reviewers stay native Claude Opus.
You are the controller. You never write implementation code yourself unless escalating (step 6).

## Setup (once per plan)
1. Use superpowers:using-git-worktrees: work on an isolated branch/worktree.
2. Check `command -v omni-task` and that ~/.config/omniroute.env exists. Missing: stop and tell the user.
3. Read the plan file. Create a TodoWrite list with one item per task. Record PLAN_BASE=`git rev-parse HEAD`.
4. Locate Superpowers' prompt templates and read them:
   Glob ~/.claude/plugins/**/subagent-driven-development/*-prompt.md
   Reuse implementer-prompt.md for briefs and the reviewer template(s) for reviews.

## Per task, strictly sequential (never two workers in the same worktree)
1. Write the brief to .omni-runs/task-<N>.md, based on implementer-prompt.md. Self-contained:
   - Full task text from the plan, verbatim (exact file paths, code, commands).
   - Relevant context: architecture notes, conventions, neighbouring files to read.
   - Follow TDD (superpowers:test-driven-development). Run only the test files the task touches,
     named explicitly; never the whole suite. Commit with the stated message, do NOT push.
   - No inline comments beyond the repo's own style; no new dependencies unless the task says so.
   - Report: what was done, test command + result, files changed, open questions.
     If blocked or the spec is ambiguous, stop and say so.
2. Dispatch: run `omni-task .omni-runs/task-<N>.md` with Bash
   (run_in_background for long tasks, then wait; otherwise timeout 600000).
   Optional second arg picks a different OmniRoute model/combo for hard tasks ($OMNI_OPUS_MODEL).
3. Worker asked a question / blocked: answer from the plan or ask the user,
   append the answer to the brief, re-dispatch.
4. Review, never trusting the worker's report. Using BASE_SHA and HEAD_SHA from the omni-task output:
   a. HEAD_SHA equals BASE_SHA: the worker committed nothing. Treat as a failed round (step 5).
   b. Spec compliance: native reviewer subagent with `model: "opus"`, the task text and
      git diff BASE_SHA..HEAD_SHA. It reads the actual code and runs the task's tests.
   c. Only if spec passes: code quality review (superpowers:requesting-code-review), also `model: "opus"`.
   Every review runs on native Opus. Never route reviews to OmniRoute or to Sonnet/Haiku.
   Reviewer briefs say "do not publish Artifacts".
5. Review fails: write .omni-runs/task-<N>-fix-<k>.md with the original task, the
   reviewer's findings verbatim (file:line), and "fix only these, re-run the task's tests, commit".
   Dispatch again, re-review. Max 3 fix rounds.
6. Escalate after 3 failed rounds or repeated worker errors (EXIT != 0, no JSON):
   tell the user, then fix natively or re-dispatch with a stronger model.
7. Mark the task complete only when both reviews approve. Then next task.

## After all tasks
- Run the full test suite once.
- Final whole-branch review (native Opus) over git diff PLAN_BASE..HEAD.
- superpowers:finishing-a-development-branch.
- Short summary: tasks done, fix rounds per task, escalations, full-suite result.

## Red flags
- Implementing code yourself instead of dispatching (except escalation).
- Accepting a task because the worker says tests pass; reviewers must run them.
- Running multiple omni-task workers concurrently in one worktree.
- Putting secrets or .env contents into briefs.
