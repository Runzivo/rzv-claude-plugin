---
description: Put a Runzivo sandbox to sleep (stop it) so it stops using credits. /workspace is kept.
argument-hint: "<sandbox-id>"
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/runzivo.sh stop) Bash(${CLAUDE_PLUGIN_ROOT}/scripts/runzivo.sh stop *)
---

Put Runzivo sandbox $ARGUMENTS to sleep. Run exactly:

```sh
${CLAUDE_PLUGIN_ROOT}/scripts/runzivo.sh stop <sandbox-id>
```

Tell the user it no longer uses credits, that `/workspace` is kept (do not
rely on anything outside it), and that `/runzivo:wake <id>` starts it again.
The lifetime timer keeps running while it sleeps.
If a command fails, show its "Next step" line and stop. Do not change
environment variables, call `rzv` directly, or work around the error.
