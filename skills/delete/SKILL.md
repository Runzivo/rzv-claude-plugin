---
description: Delete a Runzivo sandbox and its /workspace files after the user confirms.
argument-hint: "<sandbox-id>"
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/runzivo.sh delete) Bash(${CLAUDE_PLUGIN_ROOT}/scripts/runzivo.sh delete *)
---

Delete Runzivo sandbox $ARGUMENTS. Deleting is permanent.

1. Run `${CLAUDE_PLUGIN_ROOT}/scripts/runzivo.sh delete <sandbox-id>`. It deletes nothing; it shows the sandbox.
2. Show the user the name, status and credits used, and ask them to confirm
   the deletion. If they passed `--yes` in the arguments above, that is
   their confirmation.
3. Only after they confirm, run `${CLAUDE_PLUGIN_ROOT}/scripts/runzivo.sh delete <sandbox-id> --yes`.

If the user does not confirm, stop and say nothing was deleted.
If a command fails, show its "Next step" line and stop. Do not change
environment variables, call `rzv` directly, or work around the error.
