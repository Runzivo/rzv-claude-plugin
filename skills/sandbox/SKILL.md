---
description: Run commands, builds and tests in a Runzivo sandbox over SSH instead of on this machine. Use when the user asks to run work in Runzivo, on a remote VM, or in "the sandbox", or names a sandbox id (sbx_...).
argument-hint: "[sandbox-id] [task]"
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/runzivo.sh status) Bash(${CLAUDE_PLUGIN_ROOT}/scripts/runzivo.sh status *) Bash(${CLAUDE_PLUGIN_ROOT}/scripts/runzivo.sh connect) Bash(${CLAUDE_PLUGIN_ROOT}/scripts/runzivo.sh connect *)
---

# Work in a Runzivo sandbox

A Runzivo sandbox is a Linux VM (Ubuntu) reached over SSH at
the alias `<id>.rzv`. Arguments: $ARGUMENTS

## Pick the sandbox

1. If no id was given, run `${CLAUDE_PLUGIN_ROOT}/scripts/runzivo.sh status`
   and use the one running sandbox, or ask the user which one.
2. If none is running, ask the user to run `/runzivo:create` or
   `/runzivo:wake <id>`. Never create, wake or delete a sandbox on your own:
   these change what the user pays.
3. Run `${CLAUDE_PLUGIN_ROOT}/scripts/runzivo.sh connect <id>` once to write
   the SSH alias.

## Run work

- One command: `ssh <id>.rzv 'cd /workspace && <command>'`. Quote the remote
  command in single quotes.
- Long jobs: `ssh <id>.rzv 'cd /workspace && nohup <command> > job.log 2>&1 &'`,
  then check `ssh <id>.rzv 'tail -n 50 /workspace/job.log'`.
- Copy only what the task needs, and only when the user asked for remote work:
  `rsync -a --exclude .git --exclude node_modules ./ <id>.rzv:/workspace/<dir>/`.
  Copy results back with `rsync -a <id>.rzv:/workspace/<dir>/out/ ./out/`.
- Keep work in `/workspace`: it is kept when the sandbox sleeps. After a wake,
  check that tools installed outside it are still there before relying on them.

## Secrets

- Never put a secret on a command line, in an environment flag, in
  `/workspace`, or in a file you copy. Do not print one.
- If the user wants a key in the sandbox, have them pipe it over SSH stdin into
  a mode 600 file outside `/workspace`, for example:
  `ssh <id>.rzv 'umask 077; mkdir -p ~/.config/app; cat > ~/.config/app/key' < local-key-file`.
- A key file outside `/workspace` can stay until the sandbox expires or is
  deleted. Remove it when the work is done.
- Do not copy `~/.ssh`, cloud credentials or `.env` files to the sandbox.

## Limits

- Each sandbox has a lifetime (8h by default) and then stops for good. Check
  time left with `${CLAUDE_PLUGIN_ROOT}/scripts/runzivo.sh status <id>`.
- If SSH fails, run `connect <id>` again; if the sandbox expired, tell the user.
- If a command fails, show its "Next step" line and stop. Do not change
  environment variables, call `rzv` directly, or work around the error.
- Running time uses the workspace's credits. When the work is done, remind the
  user that `/runzivo:sleep <id>` stops the charge.
