---
description: Put a Runzivo sandbox to sleep (stop it) so it stops using credits. Only /workspace is kept.
argument-hint: "<sandbox-id>"
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/runzivo.sh *)
---

Put Runzivo sandbox $ARGUMENTS to sleep. Run exactly:

```sh
${CLAUDE_PLUGIN_ROOT}/scripts/runzivo.sh stop <sandbox-id>
```

Tell the user it no longer uses credits, that only `/workspace` is kept
(installed packages and files elsewhere reset), and that `/runzivo:wake <id>`
starts it again. The lifetime timer keeps running while it sleeps. If the
command fails, show its "Next step" line.
