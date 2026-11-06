# What the plugin runs and sends

- **Runs**: nothing by itself. The plugin is Markdown skills, a manifest, an
  icon and a licence. There are no scripts, hooks, MCP servers, monitors or
  executables, and no pre-approved tools: you approve each command Claude runs.
- **Calls**: the skills tell Claude to run the `rzv` CLI, from `PATH` or
  `~/.local/bin/rzv`, plus `ssh`, `rsync` and `date` for sandbox work.
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
