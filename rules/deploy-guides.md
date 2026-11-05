# Deploy Guides — One Short File per Branch

Applies to every project.

When a feature or branch needs anything at deploy time beyond a plain code release (migrations, one-off commands,
env keys, queue or worker changes, scheduler entries, cache or asset steps, data backfills, manual admin steps),
write a deploy guide for that branch before the PR.

- Location: `docs/deployment/<branch-name>.md`, with `/` in the branch name turned into `-`
  (`feat/announcement-campaigns` → `docs/deployment/feat-announcement-campaigns.md`). If the project already uses
  `docs/deploy-guides/`, use that folder instead.
- Keep it short and in order: numbered steps the deployer runs top to bottom. No design rationale.
- Sections, only those that apply:
  1. Header table: branch, PR, downtime, migrations count.
  2. Deploy log table: environment, date, deployed by, commit, result.
  3. Before deploying (backups, prerequisites).
  4. Env keys (key, value, one-line why).
  5. Deploy steps (exact commands in order, one line each on what it does).
  6. Workers and scheduler changes.
  7. Verify after deploy (short checklist).
  8. Rollback.
- Update the file whenever the branch's deploy needs change, and fill the deploy log after each deploy.
- If `docs/` is gitignored, the guide stays local; say so when the PR is opened.
