---
description: Wake (start) a sleeping Runzivo sandbox and reconnect to it.
argument-hint: "<sandbox-id>"
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/runzivo.sh *)
---

Wake Runzivo sandbox $ARGUMENTS. Run exactly:

```sh
${CLAUDE_PLUGIN_ROOT}/scripts/runzivo.sh start <sandbox-id>
${CLAUDE_PLUGIN_ROOT}/scripts/runzivo.sh connect <sandbox-id>
```

The second command waits until the sandbox runs and prints the SSH and editor
commands. Remind the user that only `/workspace` survived the sleep. A
sandbox past its lifetime cannot wake; offer `/runzivo:create` instead. If a
command fails, show its "Next step" line.
