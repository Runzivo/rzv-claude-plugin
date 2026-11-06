---
description: Print the SSH and editor commands for a running Runzivo sandbox and write its <id>.rzv SSH alias. Use when the user wants to connect to, SSH into or open a Runzivo sandbox in an editor.
argument-hint: "<sandbox-id>"
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/runzivo.sh *)
---

Connect to Runzivo sandbox $ARGUMENTS.

If no sandbox id was given, run `${CLAUDE_PLUGIN_ROOT}/scripts/runzivo.sh status` first and ask the user which
sandbox to use. Then run exactly:

```sh
${CLAUDE_PLUGIN_ROOT}/scripts/runzivo.sh connect <sandbox-id>
```

Show the user the commands it printed (`ssh <id>.rzv`, VS Code and Cursor).
If the sandbox is asleep, offer `/runzivo:wake <id>`. If the command fails,
show its "Next step" line.
