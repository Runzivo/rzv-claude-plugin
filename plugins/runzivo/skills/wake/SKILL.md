---
description: Wake (start) a sleeping Runzivo sandbox and reconnect to it.
argument-hint: "<sandbox-id>"
disable-model-invocation: true
---

Wake a Runzivo sandbox. Arguments: $ARGUMENTS

## Steps

1. Ids look like `sbx_0123456789abcdef01234567`. If none was given, run
   `rzv sandboxes list` and ask the user which one.
2. Run `rzv sandboxes start <id> --json`. A sandbox past its lifetime
   cannot wake: offer `/runzivo:create` instead.
3. Run `rzv sandboxes ssh-config <id> --write`, then `ssh <id>.rzv true`,
   which waits while SSH starts.
4. Run `rzv sandboxes get <id> --json` and report `status` and time left.

## Tell the user

It is running and using credits again. Connect with `ssh <id>.rzv`.
`/workspace` was kept; anything outside it may need setting up again.

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
