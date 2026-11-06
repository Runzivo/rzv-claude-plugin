# Commands

Every command runs `scripts/runzivo.sh`, which calls `rzv` with your own
sign-in. Sandbox ids look like `sbx_0123456789abcdef01234567`.

## /runzivo:create [name] [--size S] [--lifetime L] [--disk-gib N]

Creates a sandbox named `claude-<name>` (a timestamp when no name is given).

- `--size`: `2vcpu-8gb` (default), `4vcpu-16gb`, `8vcpu-32gb`, `16vcpu-64gb`.
  `rzv sandboxes sizes` shows what your plan and region offer.
- `--lifetime`: `8h` (default), `12h` or `24h`, where offered. The sandbox
  stops for good when its lifetime ends; it cannot be extended.
- `--disk-gib`: 5 to 64.

It waits up to five minutes for the sandbox to run (set `RUNZIVO_WAIT` in
seconds to change this), then writes the SSH alias as `connect` does.

## /runzivo:connect <id>

Runs `rzv sandboxes ssh-config <id> --write`, which adds an `<id>.rzv` host to
`~/.ssh/rzv/` and one `Include` line to `~/.ssh/config`, then prints:

```sh
ssh <id>.rzv
code --remote ssh-remote+<id>.rzv /workspace
cursor --remote ssh-remote+<id>.rzv /workspace
```

## /runzivo:status [<id>]

Without an id: every sandbox in the workspace that is not deleted. With an id:
status, size, lifetime, time left, expiry, running time and credits used.
Credits are equivalent minutes from the plan allowance or prepaid credit.

## /runzivo:sleep <id> and /runzivo:wake <id>

`sleep` runs `rzv sandboxes stop`: compute charges stop and `/workspace` is
kept. Everything outside `/workspace` resets. The lifetime timer keeps running.
`wake` runs `rzv sandboxes start` and reconnects.

## /runzivo:delete <id>

Shows the sandbox and asks you to confirm before it runs
`rzv sandboxes delete`. `/runzivo:delete <id> --yes` confirms up front. It
also removes the `<id>.rzv` SSH alias.

## Who can run what

Claude may run `status`, `connect` and the `sandbox` skill on its own. Only you
can start `create`, `sleep`, `wake` and `delete`, because they change what you
pay or delete files.

Back to the [README](../README.md).
