---
description: Delete a Runzivo sandbox and its /workspace files, only after the user confirms.
argument-hint: "<sandbox-id> [--yes]"
disable-model-invocation: true
---

Delete a Runzivo sandbox. Deleting is permanent. Arguments: $ARGUMENTS

## Steps

1. Ids look like `sbx_0123456789abcdef01234567`. If none was given, run
   `rzv sandboxes list` and ask the user which one. Delete only one sandbox.
2. Run `rzv sandboxes get <id> --json` and show the name, status and
   credits used.
3. Confirmation: if the arguments above contain `--yes`, the user has
   confirmed. Otherwise ask the user to confirm and stop here. Say that
   nothing was deleted, and that `/runzivo:delete <id> --yes` deletes it.
   A later explicit "yes" from the user in this conversation also confirms.
4. Only after confirmation, run `rzv sandboxes delete <id> --json`.
5. Remove the SSH alias `rzv` wrote for it: `rm -f ~/.ssh/rzv/<id>.conf`.
   Remove no other file.

## Tell the user

The sandbox and all its files are deleted, or that nothing was deleted.

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
