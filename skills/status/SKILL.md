---
description: Show Runzivo sandboxes with their status, time left, expiry and credits used. Use when the user asks which sandboxes are running, how long one has left, or what it has cost.
argument-hint: "[sandbox-id]"
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/runzivo.sh *)
---

Show Runzivo sandbox status. Run exactly one of:

```sh
${CLAUDE_PLUGIN_ROOT}/scripts/runzivo.sh status                  # every sandbox that is not deleted
${CLAUDE_PLUGIN_ROOT}/scripts/runzivo.sh status <sandbox-id>     # one sandbox in detail
```

Use `${CLAUDE_PLUGIN_ROOT}/scripts/runzivo.sh status <sandbox-id> --json` when you need exact fields
(`status`, `remaining_seconds`, `expires_at`, `credits_used`).

Arguments: $ARGUMENTS

Summarise for the user: status, time left, expiry (local time), and credits
used. Credits are equivalent minutes drawn from the workspace's plan allowance
or prepaid credit; a 2vcpu-8gb sandbox uses one per running minute. A sleeping
sandbox uses none. If the command fails, show its "Next step" line.
