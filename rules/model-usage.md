# Model and Effort Limits

Applies to every project and every session.

- Never run the Fable 5 model (`claude-fable-5-1`, any Fable variant) — not for the main session, a subagent, a workflow, or a `model` override.
- Never run Claude Opus at ultra or max effort, and never start ultracode / multi-agent "ultra" runs.
- If a task seems to need either one, stop and ask first. Name the model or effort level and why.
- If the user declines, do not run it, and do not ask again for the rest of that work.
- Default to Opus or Sonnet at normal effort for agents; use Haiku for cheap mechanical work.
