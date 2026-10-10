# claude-code-config

This repository is the shared global Claude Code config for all of the owner's machines (macOS and
Windows). `sync.sh` copies it between `~/.claude` and the repository. The human guide is the
"Keeping machines in sync" section of `README.md`; this file is the procedure Claude follows.

## Hard rules

- Never push to `main`. Every change goes through a `sync/...` branch and a pull request.
- Never commit secrets. The repository is public. If `sync.sh` reports a secret-looking `env` key, stop
  and ask.
- Never pass `--prune`, and never delete a rule, skill or setting, without asking first.
- Keep macOS and Windows both working. Shared files must stay platform-neutral. Platform-only values go
  in the README Platform guide or in `MACHINE_ONLY_ENV`, never in the shared `settings.json`.
- `install.sh` and `sync.sh` must keep LF line endings (`.gitattributes` enforces this).

## Sync procedure ("sync my global config")

1. `git switch main && git pull`. If the working tree is dirty, ask what to do with the changes.
2. Run `./sync.sh status`.
3. Every item `same`: report "in sync" and stop.
4. Work out a direction for each item that is not `same`:
   - `machine-only`: publish it, unless `git log --diff-filter=D -- <path>` shows another machine
     deleted it from the repository. In that case, ask.
   - `repo-only`: import it, unless this machine deleted it on purpose. If unsure, ask.
   - `differs`: always ask. Compare the file's modification time in `~/.claude` with
     `git log -1 --format=%cI -- <path>`, show `git diff --no-index <repo path> <machine path>`, and
     recommend the newer side.
5. Apply the answers. `publish` and `export` always take every machine item, and `import` always takes
   every repository item, so make both sides agree item by item first:
   - Take the repository copy: copy only that item from the repository into `~/.claude`, after a
     `.bak.<timestamp>` backup.
   - Merge by hand: write the merged result into `~/.claude`.
   - Skip: use the manual flow from the README and `git restore <path>` each skipped item before the
     commit. Do not run `import` afterwards; copy `repo-only` items into `~/.claude` one by one instead.
   Then run `./sync.sh publish`. When nothing was skipped, run `./sync.sh import` afterwards to bring
   `repo-only` items to this machine.
6. Give the user the PR link. After merge, remind them to run `git pull && ./sync.sh import` on the
   other machines and restart Claude Code.
7. If a plugin or MCP server was added or removed, also update `install.sh` and README sections 3 and 4
   on the same branch before the PR is merged.

## Asking the user

Whenever anything about a sync is unclear, stop and ask with the AskUserQuestion tool. Do not guess.
Examples: which side of a `differs` item is newer, deletions, a secret-looking key, a merge conflict,
a dirty working tree, or a setting that might be platform-specific.

- Give exactly 4 options per question.
- Put the recommended option first and end its label with "(Recommended)". Say why in its description,
  based on evidence such as dates, diffs or git history.
- One decision per question. Batch up to 4 questions in one call when several items need decisions.

Example for a `differs` item:

| Option | Description |
| --- | --- |
| Publish this machine's copy (Recommended) | `~/.claude` copy changed after the last repo commit that touched it |
| Import the repo copy | Overwrites the local copy; a `.bak.<timestamp>` backup is kept |
| Merge both by hand | Show the diff, combine both versions, then publish |
| Skip for now | Leave both sides as they are and report it as still out of sync |
