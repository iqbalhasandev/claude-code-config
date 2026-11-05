# Pull Requests — Assign the User

Applies to every project and every session.

- Every pull request Claude creates is assigned to the user: pass `--assignee @me` to `gh pr create`, or run
  `gh pr edit <number> --add-assignee @me` right after creating it.
- Add the fitting labels from the repo's own set (`gh label list`): `bug` for a fix, `enhancement` or
  `new feature` for new behaviour, `documentation` for docs-only. Never create new labels.
- Confirm the assignee and labels in the final message along with the PR link.

Reason: the user wants every PR opened on their behalf to show them as the assignee.
