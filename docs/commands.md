# Commands

Each command is a skill: instructions that tell Claude which `rzv` command to
run, with your own sign-in. Claude Code asks you to approve each command.
Sandbox ids look like `sbx_0123456789abcdef01234567`.

## /runzivo:create [name] [--size S] [--lifetime L] [--disk-gib N]

Creates a sandbox named `claude-<name>` (a timestamp when no name is given).

- `--size`: `2vcpu-8gb` (default), `4vcpu-16gb`, `8vcpu-32gb`, `16vcpu-64gb`.
  `rzv sandboxes sizes` shows what your plan and region offer.
- `--lifetime`: `8h` (default), `12h` or `24h`, where offered. The sandbox
  stops for good when its lifetime ends; it cannot be extended.
- `--disk-gib`: 5 to 64.

Claude runs `rzv sandboxes create --name claude-<name> ... --json` once,
checks `sleep 10 && rzv sandboxes get <id> --json` (one approval each) until it runs (up to
five minutes), then writes the SSH alias as `connect` does. It never retries a create on its own.

## /runzivo:connect <id>

Runs `rzv sandboxes ssh-config <id> --write`, which adds an `<id>.rzv` host to
`~/.ssh/rzv/` and one `Include` line to `~/.ssh/config`, then prints:

```sh
ssh <id>.rzv
code --remote ssh-remote+<id>.rzv /workspace
cursor --remote ssh-remote+<id>.rzv /workspace
```

## /runzivo:status [<id>]

Without an id: every sandbox in the workspace that is not deleted
(`rzv sandboxes list --json`). With an id: status, size, lifetime, time left,
expiry and credits used, from `rzv sandboxes get <id> --json`.
Credits are equivalent minutes from the plan allowance or prepaid credit.

## /runzivo:sleep <id> and /runzivo:wake <id>

`sleep` runs `rzv sandboxes stop`: compute charges stop and `/workspace` is
kept. Do not rely on files outside `/workspace` being kept. The lifetime timer
keeps running.
`wake` runs `rzv sandboxes start` and reconnects.

## /runzivo:delete <id>

Shows the sandbox and asks you to confirm before it runs
`rzv sandboxes delete <id> --json`. `/runzivo:delete <id> --yes` confirms up
front. It then removes the `~/.ssh/rzv/<id>.conf` SSH alias.

## Who can run what

Claude may run `status`, `connect` and the `sandbox` skill on its own. Only you
can start `create`, `sleep`, `wake` and `delete`, because they change what you
pay or delete files.

Back to the [README](../README.md).
