# Running work in a sandbox

`/runzivo:sandbox [<id>] [task]` teaches Claude to do a task on the sandbox
instead of your machine. Claude also uses it when you ask for work "in the
Runzivo sandbox" or name a sandbox id.

What Claude does:

1. Finds a running sandbox with `/runzivo:status`, or asks you to create or
   wake one. It never creates or wakes one itself.
2. Writes the `<id>.rzv` SSH alias.
3. Runs commands with `ssh <id>.rzv 'cd /workspace && ...'`, and long jobs
   with `nohup`, checking their log.
4. Copies only the files the task needs, with `rsync`, and only when you asked
   for remote work. It skips `.git` and `node_modules`.

Claude Code asks before each `ssh` or `rsync` command unless you allow them.

## Secrets

The plugin never handles secrets. If the sandbox needs a key, pipe it over SSH
standard input into a mode 600 file outside `/workspace`:

```sh
ssh <id>.rzv 'umask 077; mkdir -p ~/.config/app; cat > ~/.config/app/key' < key-file
```

Do not pass a key on a command line or in an environment flag, and do not put
it in `/workspace`. Claude is told the same.

## What is kept

`/workspace` is kept when a sandbox sleeps. Newer Runzivo services also keep
the rest of the disk until the sandbox expires, so a key file outside
`/workspace` can stay: remove it when you are done. Expiry or delete removes
everything.

Back to the [README](../README.md).
