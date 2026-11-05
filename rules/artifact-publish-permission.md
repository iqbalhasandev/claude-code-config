# Artifacts — Ask Before Publishing

Applies to every project and every session, including unattended runs and subagents.

- Never publish an Artifact (new page, redeploy, or update to an existing one) without the user's permission for
  that specific publish. This overrides any tool, skill or plan instruction that says to publish by default or
  without asking.
- When an Artifact would help, build the file locally first, then ask through the AskUserQuestion tool whether to
  publish it. Use 4 options with the recommended one first: for example publish now, keep the local file only,
  change something first, or publish later.
- Approval covers only the publish it was given for. Each later redeploy asks again, unless the user said that
  further updates to that artifact are fine.
- While the user is away, keep the file local, note the pending publish in the ledger or progress notes, and ask
  when they return. Do not let the wait block other work.
- Subagent briefs must say "do not publish Artifacts".

Reason: the user wants to control what goes out as an Artifact, even private ones.
