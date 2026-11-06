---
description: Put a Runzivo sandbox to sleep (stop it) so it stops using credits. /workspace is kept.
argument-hint: "<sandbox-id>"
disable-model-invocation: true
---

Put a Runzivo sandbox to sleep. Arguments: $ARGUMENTS

## Steps

1. Ids look like `sbx_0123456789abcdef01234567`. If none was given, run
   `rzv sandboxes list` and ask the user which one.
2. Run `rzv sandboxes stop <id> --json`.
3. Run `rzv sandboxes get <id> --json` and report its `status`.

## Tell the user

It no longer uses compute credits. `/workspace` is kept; do not rely on
anything outside it. The lifetime timer keeps running while it sleeps.
`/runzivo:wake <id>` starts it again.

## Running rzv

- Run each command yourself with the Bash tool. The user approves each one.
- Use `rzv` from PATH. If the shell says command not found (exit 127), use
  `~/.local/bin/rzv` in its place. If that is missing too, stop and tell the
  user to install the Runzivo CLI and sign in:
  follow https://runzivo.dev/docs/cli/ to install `rzv`, then run `rzv login`.
- If `rzv` rejects a command or flag, run `rzv --version`. Below 0.26.0, ask
  the user to install it again from that page.
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
