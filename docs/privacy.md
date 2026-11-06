# What the plugin runs and sends

- **Runs**: one Bash script, `scripts/runzivo.sh`, from the skills. There are
  no hooks, MCP servers, monitors or executables on your PATH.
- **Calls**: only the `rzv` CLI, found in `RZV_BIN`, then `PATH`, then
  `~/.local/bin/rzv`. The script makes no network requests itself.
- **Sends**: `rzv` sends the sandbox name, size, lifetime and disk size you
  choose to the Runzivo API, with your existing `rzv` sign-in. The plugin adds
  no telemetry. Sandboxes it creates are named `claude-...` so Runzivo can
  count plugin use; no other activity is collected.
- **Stores**: nothing of its own. `rzv` writes SSH host entries under
  `~/.ssh/rzv/` and one `Include` line in `~/.ssh/config`. Delete removes the
  entry for that sandbox.
- **Reads**: none of your project files. Files reach a sandbox only when you
  ask Claude to run work there, through `ssh` or `rsync` commands you can see.
- **Secrets**: none are bundled, requested or stored. `rzv` never prints its
  tokens.

Runzivo's privacy policy: https://runzivo.dev/legal/privacy

Back to the [README](../README.md).
