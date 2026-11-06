# Testing

## Every change

```sh
shellcheck scripts/*.sh tests/run.sh tests/fake-rzv
tests/run.sh
claude plugin validate --strict --profile directory .
```

CI runs the first two. `tests/run.sh` drives `scripts/runzivo.sh` against
`tests/fake-rzv`, offline: names, arguments, the delete confirmation, SSH
alias cleanup, error hints and the rzv lookup and version check.
`claude plugin validate` needs Claude Code; run it before each tag.

## Live end-to-end test

`scripts/20-shared-e2e.sh` runs the slash commands through `claude -p
--plugin-dir .` against a Runzivo test environment and checks each step with
`rzv`:

1. Errors: no `rzv`, and a profile that is not signed in.
2. `/runzivo:create`: a running `claude-e2e-...` sandbox and its SSH alias.
3. `/runzivo:sandbox`: Claude runs a task over SSH that writes `/workspace`.
4. `/runzivo:status`: credits are metered while it runs.
5. `/runzivo:sleep`: stopped, and credits do not grow.
6. `/runzivo:wake`: running again, and `/workspace` survived.
7. `/runzivo:delete`: nothing is deleted without confirmation; with `--yes`
   the sandbox and its SSH alias are gone.

```sh
RZV_PROFILE=<profile> E2E_EVIDENCE=<dir> scripts/20-shared-e2e.sh
```

It needs `claude`, `rzv`, `ssh` and `python3`, a free sandbox slot, and about
ten minutes. It uses the `claude-haiku-5-5` model (`E2E_MODEL`), aborts unless
`rzv whoami` shows the `E2E_ENVIRONMENT` environment (default `shared`), and
deletes its sandbox even on failure. Set `E2E_LOCK` to a directory path to
take turns with other test runs.

Back to the [README](../README.md).
