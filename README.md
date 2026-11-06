# Runzivo for Claude Code

Run your work in a [Runzivo](https://runzivo.dev) sandbox, a Linux virtual
machine billed by the minute, without leaving Claude Code. This plugin adds
slash commands to create a sandbox, connect to it over SSH or from your
editor, check its time left and credits, put it to sleep, wake it, and delete
it. A skill teaches Claude to run builds and tests in the sandbox over SSH.

## Install

You need the Runzivo CLI, `rzv` 0.26.0 or later, signed in:

```sh
curl -fsSL https://runzivo.dev/downloads/rzv/install.sh | sh
rzv login
```

Then add this repository as a marketplace and install the plugin:

```sh
claude plugin marketplace add Runzivo/rzv-claude-plugin
claude plugin install runzivo@runzivo
```

Inside a session, `/plugin marketplace add Runzivo/rzv-claude-plugin` and
`/plugin install runzivo@runzivo` do the same.

## Commands

| Command | What it does |
| - | - |
| `/runzivo:create [name] [--size S] [--lifetime L] [--disk-gib N]` | Create `claude-<name>`, wait for it and write the `<id>.rzv` SSH alias |
| `/runzivo:connect <id>` | Print `ssh <id>.rzv`, VS Code and Cursor commands |
| `/runzivo:status [<id>]` | Status, time left, expiry and credits used |
| `/runzivo:sleep <id>` / `/runzivo:wake <id>` | Stop or start the sandbox |
| `/runzivo:delete <id>` | Delete after you confirm |
| `/runzivo:sandbox [<id>] [task]` | Run a task in the sandbox over SSH |

Claude can use `connect`, `status` and `sandbox` on its own. It never creates,
wakes, sleeps or deletes a sandbox unless you run the command. Details:
[docs/commands.md](docs/commands.md) and [docs/sandbox-work.md](docs/sandbox-work.md).

## What it runs and sends

The plugin runs one shell script, `scripts/runzivo.sh`, which calls the `rzv`
CLI on your machine. It makes no network calls of its own, stores no tokens,
ships no AI provider keys, and reads none of your project files. `rzv` talks
to the Runzivo API with your own sign-in. When you ask Claude to run work in a
sandbox, Claude copies the files that task needs over SSH. See
[docs/privacy.md](docs/privacy.md).

Sandbox time uses your workspace's equivalent-minute credits. `/workspace`
is kept when a sandbox sleeps; do not rely on anything outside it.

## More

[Troubleshooting](docs/troubleshooting.md) · [Testing](docs/testing.md) ·
[Releasing](docs/releasing.md) · [Changelog](CHANGELOG.md)

MIT licensed. Runzivo service terms: https://runzivo.dev/legal/terms
