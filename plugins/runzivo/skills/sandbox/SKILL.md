---
description: Run commands, builds and tests in a Runzivo sandbox over SSH instead of on this machine. Use when the user asks to run work in Runzivo, on a remote VM, or in "the sandbox", or names a sandbox id (sbx_...).
argument-hint: "[sandbox-id] [task]"
---

# Work in a Runzivo sandbox

A Runzivo sandbox is an Ubuntu VM reached over SSH at the alias `<id>.rzv`.
Arguments: $ARGUMENTS

## Pick the sandbox

1. If no id was given, run `rzv sandboxes list --json` and use the one
   sandbox whose `status` is `running`, or ask the user which one.
2. If none is running, ask the user to run `/runzivo:create` or
   `/runzivo:wake <id>`. Never create, wake, sleep or delete a sandbox on
   your own: that changes what the user pays or deletes files.
3. Run `rzv sandboxes ssh-config <id> --write` once to write the alias.

## Run work

- One command: `ssh <id>.rzv 'cd /workspace && <command>'`, with the remote
  command in single quotes.
- Long jobs: `ssh <id>.rzv 'cd /workspace && nohup <command> > job.log 2>&1 &'`,
  then `ssh <id>.rzv 'tail -n 50 /workspace/job.log'`.
- Copy only what the task needs, and only when the user asked for remote work:
  `rsync -a --exclude .git --exclude node_modules ./ <id>.rzv:/workspace/<dir>/`.
  Copy results back with `rsync -a <id>.rzv:/workspace/<dir>/out/ ./out/`.
- Keep work in `/workspace`: it is kept when the sandbox sleeps. After a wake,
  check that tools installed outside it are still there.
- If SSH fails, run `rzv sandboxes get <id> --json`: a stopped sandbox needs
  `/runzivo:wake <id>`, an expired one a new `/runzivo:create`.

## Secrets

- Never put a secret on a command line, in an environment flag (never
  `rzv sandboxes exec --env`), in `/workspace`, or in a file you copy.
  Never print one. Do not copy `~/.ssh`, cloud credentials or `.env` files.
- If the user wants a key in the sandbox, have them pipe it over SSH stdin
  into a mode 600 file outside `/workspace`, for example
  `ssh <id>.rzv 'umask 077; mkdir -p ~/.config/app; cat > ~/.config/app/key' < local-key-file`.
  Remind them to remove it when the work is done.

## Cost

Each sandbox has a lifetime (8h by default) and then stops for good; check
`remaining_seconds` with `rzv sandboxes get <id> --json`. Running time uses
the workspace's credits. When the work is done, remind the user that
`/runzivo:sleep <id>` stops the charge.

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
