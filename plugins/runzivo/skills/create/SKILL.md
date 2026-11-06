---
description: Create a Runzivo sandbox (a Linux VM billed in equivalent minutes) and set up SSH to it. Use when the user asks for a new Runzivo sandbox or remote dev VM.
argument-hint: "[name] [--size 2vcpu-8gb|4vcpu-16gb|8vcpu-32gb|16vcpu-64gb] [--lifetime 8h|12h|24h] [--disk-gib 5-64]"
disable-model-invocation: true
---

Create one Runzivo sandbox. Arguments: $ARGUMENTS

## Steps

1. Build the name. Take the words in the arguments that are not options,
   lowercase them, turn every run of other characters into one `-`, trim
   `-` from both ends, cut to 40 characters, and drop a leading `claude-`.
   The name is `claude-<slug>`. With no words, run `date -u +%Y%m%d-%H%M%S`
   and use `claude-<that output>`.
2. Check the options. `--size` is one of 2vcpu-8gb (default), 4vcpu-16gb,
   8vcpu-32gb, 16vcpu-64gb. `--lifetime` is 8h (default), 12h or 24h.
   `--disk-gib` is a whole number from 5 to 64. If one is wrong, tell the
   user the allowed values and stop. Pass only the options the user gave.
3. Create it, once:
   `rzv sandboxes create --name claude-<slug> [--size S] [--lifetime L] [--disk-gib N] --json`
   Read the sandbox id (`sbx_...`) from the output. Never retry a create on
   your own: each create starts a new billed sandbox.
4. Write the SSH alias: `rzv sandboxes ssh-config <id> --write`.
5. Wait for it to start: `ssh <id>.rzv true`. This waits while SSH starts.
   If it times out, run `rzv sandboxes get <id> --json` and report the status.
6. Run `rzv sandboxes get <id> --json` for the final details.

## Tell the user, briefly

- id, name, size, lifetime and expiry (`expires_at`, in local time)
- connect with `ssh <id>.rzv`, `code --remote ssh-remote+<id>.rzv /workspace`
  or `cursor --remote ssh-remote+<id>.rzv /workspace`
- it uses credits (equivalent minutes) while running; `/runzivo:sleep <id>`
  stops the charge and `/runzivo:delete <id>` removes it
- `/workspace` is kept when it sleeps; do not promise anything else is kept

## Running rzv

- Run each command yourself with the Bash tool. The user approves each one.
- Use `rzv` from PATH. If the shell reports `rzv: command not found`, use
  `~/.local/bin/rzv` in its place. If that is missing too, stop and tell the
  user to install the Runzivo CLI and sign in:
  `curl -fsSL https://runzivo.dev/downloads/rzv/install.sh | sh`, then `rzv login`.
- If `rzv` rejects a command or flag, run `rzv --version`. Below 0.26.0, ask
  the user to install it again with the command above.
- Never print, copy or ask for tokens or keys. Do not change environment
  variables or `RZV_PROFILE`, and do not work around an error.

## When a command fails

`rzv ... --json` prints an error such as `{"error":"credit_exhausted",...}`.
Show the user the error and the matching next step, then stop:

- `authentication_required`, `reauth_required`, or exit status 3: run `rzv login` in a terminal (it opens a browser), then try again.
- `credit_exhausted`: add credit in the Runzivo portal, under Billing.
- `sandbox_limit_reached`: sleep or delete a running sandbox (`/runzivo:status` lists them).
- `sandbox_capacity_busy` or `no_capacity`: wait a few minutes, or choose a smaller size.
- `plan_required` or `size_unavailable`: choose a size from `rzv sandboxes sizes`.
- `sandbox_not_found`, `not_found`, or exit status 6: no such sandbox here; `/runzivo:status` lists them.
- `sandbox_expired`: the lifetime ended; create a new sandbox with `/runzivo:create`.
- `sandbox_wrong_state`: it is starting or stopping; check `/runzivo:status` shortly.
- Anything else: show the message and suggest `rzv whoami` to check the sign-in.
