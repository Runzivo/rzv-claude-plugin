---
description: Create a Runzivo sandbox (a Linux VM billed in equivalent minutes) and set up SSH to it. Use when the user asks for a new Runzivo sandbox or remote dev VM.
argument-hint: "[name] [--size 2vcpu-8gb|4vcpu-16gb|8vcpu-32gb|16vcpu-64gb] [--lifetime 8h|12h|24h] [--disk-gib 5-64]"
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/runzivo.sh create) Bash(${CLAUDE_PLUGIN_ROOT}/scripts/runzivo.sh create *)
---

Create a Runzivo sandbox with these arguments: $ARGUMENTS

Run exactly:

```sh
${CLAUDE_PLUGIN_ROOT}/scripts/runzivo.sh create $ARGUMENTS
```

The sandbox is named `claude-<name>`; with no name it gets a timestamp. The
default size is 2vcpu-8gb and the default lifetime is 8h. The command waits
for the sandbox to start and writes its `<id>.rzv` SSH alias.

Then tell the user, briefly:

- the sandbox id, name, size, lifetime and expiry time
- the `ssh <id>.rzv` and editor commands the script printed
- that it uses credits (equivalent minutes) while running, that
  `/runzivo:sleep <id>` stops the charge, and `/runzivo:delete <id>` removes it
- that `/workspace` is kept when the sandbox sleeps; nothing else is promised

If a command fails, show its "Next step" line and stop. Do not change
environment variables, call `rzv` directly, or work around the error.
Do not retry a create on your own: each create starts a new billed sandbox.
