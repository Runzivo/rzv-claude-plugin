# Runzivo plugin for Claude Code

Skills that let Claude create, connect to, check, sleep, wake and delete
[Runzivo](https://runzivo.dev) sandboxes (Linux VMs billed by the minute),
and run work in them over SSH.

The skills are instructions only. Claude runs the `rzv` CLI (0.26.0 or later)
on your machine, and Claude Code asks you to approve each command. The plugin
ships no scripts, hooks, MCP servers or keys, and grants no tools.

## Install

```sh
claude plugin marketplace add Runzivo/rzv-claude-plugin
claude plugin install runzivo@runzivo
```

In a session: `/plugin install runzivo --marketplace Runzivo/rzv-claude-plugin`.

## Skills

| Skill | What it does |
| - | - |
| `/runzivo:create [name] [--size S] [--lifetime L] [--disk-gib N]` | Create `claude-<name>` and write its `<id>.rzv` SSH alias |
| `/runzivo:connect <id>` | Write the SSH alias; show `ssh` and editor commands |
| `/runzivo:status [<id>]` | Status, time left, expiry and credits used |
| `/runzivo:sleep <id>` / `/runzivo:wake <id>` | Stop or start the sandbox |
| `/runzivo:delete <id> [--yes]` | Delete after you confirm |
| `/runzivo:sandbox [<id>] [task]` | Run a task in the sandbox over SSH |

Install, privacy and troubleshooting:
https://github.com/Runzivo/rzv-claude-plugin#readme

MIT licensed. Runzivo service terms: https://runzivo.dev/legal/terms
