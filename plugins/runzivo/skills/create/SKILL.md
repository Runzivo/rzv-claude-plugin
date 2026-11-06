---
description: Create a Runzivo sandbox (a Linux VM billed in equivalent minutes) and set up SSH to it. Use when the user asks for a new Runzivo sandbox or remote dev VM.
argument-hint: "[name] [--size 2vcpu-8gb|4vcpu-16gb|8vcpu-32gb|16vcpu-64gb] [--lifetime 8h|12h|24h] [--disk-gib 5-64]"
disable-model-invocation: true
---

Create one Runzivo sandbox. Arguments: $ARGUMENTS

## Steps

1. Build the name from the words in the arguments that are not options or
   option values. Lowercase them, replace every run of characters other than
   `a-z`, `0-9` and `-` with one `-`, drop a leading `claude-`, cut to 40
   characters, then trim `-` from both ends. The name is `claude-<slug>`. If
   the slug is empty, run `date -u +%Y%m%d-%H%M%S` and use `claude-<output>`.
2. Check the options. `--size` is one of 2vcpu-8gb (default), 4vcpu-16gb,
   8vcpu-32gb, 16vcpu-64gb. `--lifetime` is 8h (default), 12h or 24h.
   `--disk-gib` is a whole number from 5 to 64. If one is wrong, or an
   option is unknown, tell the user the allowed values and stop. Pass only the options the user gave.
3. Create it, once:
   `rzv sandboxes create --name claude-<slug> [--size S] [--lifetime L] [--disk-gib N] --json`
   Read the sandbox id (`sbx_...`) from the output. Never retry a create on
   your own: each create starts a new billed sandbox.
4. Wait until it runs: run `rzv sandboxes get <id> --json` and read
   `sandbox.status`. While it is `pending`, `creating`, `provisioning`,
   `starting` or `stopping`, check again with the single
   command `sleep 10 && rzv sandboxes get <id> --json`, for up to 5 minutes.
   Stop on `failed` (report `sandbox.error.code`), `expired`, `deleted` or
   `cleanup_pending`, and on
   `stopped`.
5. Write the SSH alias: `rzv sandboxes ssh-config <id> --write`.
6. Check SSH with `ssh <id>.rzv true`. It waits while SSH starts; if it still
   fails, the sandbox is created: tell the user to run `/runzivo:connect <id>`
   in a minute.

## Tell the user, briefly

- id, name, size, lifetime and expiry (`expires_at`, in local time)
- connect with `ssh <id>.rzv`, `code --remote ssh-remote+<id>.rzv /workspace`
  or `cursor --remote ssh-remote+<id>.rzv /workspace`
- it uses credits (equivalent minutes) while running; `/runzivo:sleep <id>`
  stops the charge and `/runzivo:delete <id>` removes it
- `/workspace` is kept when it sleeps; do not promise anything else is kept

## Running rzv

- Run each command yourself with the Bash tool. The user approves each one.
- Use `rzv` from PATH. If the shell says command not found (exit 127), use
  `~/.local/bin/rzv` in its place. If that is missing too, stop and tell the
  user to install the Runzivo CLI and sign in:
  follow https://runzivo.dev/docs/cli/ to install `rzv`, then run `rzv login`.
- If `rzv` rejects a command or flag, run `rzv --version`. Below 0.26.0, ask
  the user to install it again with the command above.
- Never print, copy or ask for tokens or keys. Do not change environment
  variables or `RZV_PROFILE`, and do not work around an error.

## When a command fails

`rzv ... --json` prints an error such as `{"error":"credit_exhausted",...}`.
A sandbox whose `status` is `failed` gives the reason in `sandbox.error.code`.
Show the user the error and the matching next step, then stop:

- `authentication_required`, `reauth_required`, or exit status 3: run `rzv login` in a terminal (it opens a browser), then try again.
- `credit_exhausted`: add credit in the Runzivo portal, under Billing.
- `sandbox_limit_reached`: sleep or delete a running sandbox (`/runzivo:status` lists them).
- `sandbox_capacity_busy` or `no_capacity`: wait a few minutes, or choose a smaller size.
- `plan_required` or `size_unavailable`: choose a size from `rzv sandboxes sizes`.
- `lifetime_unavailable`: that lifetime is not offered here; leave `--lifetime` out to get 8h.
- `sandbox_name_taken`: choose another name.
- `sandbox_not_found`, `not_found`, or exit status 6: no such sandbox here; `/runzivo:status` lists them.
- `sandbox_expired`: the lifetime ended; create a new sandbox with `/runzivo:create`.
- `sandbox_wrong_state` or `sandbox_ssh_starting`: it is starting or stopping; try again in a minute.
- `access_denied`, `insufficient_role`, `permission_required`, or exit status 4: the user's Runzivo role does not allow this; ask a workspace owner.
- `workspace_blocked` or `workspace_closed`: contact Runzivo support.
- `service_unavailable`, `customer_api_unavailable`, or exit status 5: Runzivo is not reachable; try again in a few minutes.
- Anything else: show the message and suggest `rzv whoami` to check the sign-in.
