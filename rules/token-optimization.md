# Token Use — Spend Only What the Work Needs

Applies to every project and every session, including subagents, workflows and unattended runs.

## Reading

- Search before reading: grep or glob for the symbol, then read only the line range you need. Never read a whole
  large file, lockfile, generated file, minified asset, lang JSON or snapshot to find one thing.
- Read a file once per task. Do not re-read a file you just edited or already have in context.
- Logs and command output: read the tail or a grep, never the full log. Cap output with `| tail -n`, `| head`,
  `--quiet`, `--compact` or a JSON summary flag.
- Never read a subagent transcript or output file; wait for its report.
- Use the codebase map, project memory and project rule files first; open source files only for details they lack.

## Memory and project notes

- Before starting work, check project memory (MEMORY.md and the linked files) and the project ledger or progress file
  for decisions already made. Do not rediscover or re-ask what is recorded.
- Record settled decisions, traps and resume points in project memory or the ledger once, so later sessions and
  subagents read a short note instead of re-deriving it.
- Keep MEMORY.md to one line per entry and memory files short. Update an entry in place; do not add duplicates.
- Long-running work keeps a ledger with a clear resume point, so a compaction or new session restarts cheaply.

## Subagents

- Spawn an agent only for independent or parallel work, or a sweep across many files. Do a handful of tool calls
  yourself.
- Never launch an agent that duplicates work already running or done.
- Briefs point at exact files and line ranges and state the decisions already made. Put shared rules in one file
  that every agent reads, instead of repeating them in each brief. No "read the whole plan".
- Ask for concise reports: result, files, test counts, open questions. Have the full report written to a file.
- Pick the cheapest model that can do the job (see subagent-models.md). Never run a bigger model or effort level
  "to be safe".

## Review loops

- Review diffs: small context (`-U3` to `-U5`), and leave out generated files, lockfiles, minified assets, build
  output and translation JSON. Check translation files with a short script (missing pairs, bad characters) instead.
- One review pass per task. Run a re-review only when the fix round closed Critical or Important findings. Check
  minor-only fixes yourself with the test output and a grep.
- Fold leftovers into the next fix round instead of starting a new round for them.
- Reviewers run only the task's own tests, not whole folders the builder already ran.

## Tests and tools

- Targeted test runs while working, full suite once at the end (see test-runs.md). Use quiet or compact output.
- Run slow independent steps at the same time when they do not share state (test suite during screenshot
  capture, for example).
- Do not poll. Wait for the completion notification of background work.
- Batch independent tool calls in one message. Load deferred tools in one search call.

## Replies

- Short replies: result first, no recap of the conversation, no restating tool output the user did not ask for.
- No progress chatter between tool calls.
- Do not paste large file contents, diffs or logs into a reply; give the path and the key line.

Reason: the user saw tokens burned in many places (oversized review diffs, repeated re-reviews, long briefs, full
log reads) and wants every project to run lean.
