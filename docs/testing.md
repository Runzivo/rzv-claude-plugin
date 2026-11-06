# Testing

## Every change

```sh
shellcheck scripts/*.sh tests/run.sh
tests/run.sh
claude plugin validate --strict --profile directory plugins/runzivo
claude plugin validate --strict .
```

CI runs the first two. `tests/run.sh` checks, offline, that `plugins/runzivo/`
holds only the file types Anthropic's directory allows, that no skill grants
tools beyond Read, Grep, Glob and LS, that the manifests and changelog agree,
and that each skill names the `rzv` commands, the `claude-` name, the delete
confirmation and the error hints. `claude plugin validate` needs Claude Code;
run it before each tag.

## Live end-to-end test

`scripts/20-shared-e2e.sh` runs the slash commands through `claude -p
--plugin-dir plugins/runzivo` against a Runzivo test environment and checks each step with
`rzv`:

1. Errors: no `rzv` (empty home, no `rzv` on PATH), and a profile that is
   not signed in.
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

The plugin grants no tools, so the test passes `--allowedTools` for the
commands the skills run (`rzv`, `ssh`, `date`, removing an SSH alias). Only
the test does this; users approve each command. It needs `claude`, `rzv`, `ssh` and `python3`, a free sandbox slot, and about
ten minutes. It uses the `claude-haiku-5-5` model (`E2E_MODEL`), aborts unless
`rzv whoami` shows the `E2E_ENVIRONMENT` environment (default `shared`), and
deletes its sandbox even on failure. Set `E2E_LOCK` to a directory path to
take turns with other test runs (it writes an `owner` file while it runs); it gives up after `E2E_LOCK_WAIT` seconds
(default 3600). It also records whether the home directory survived sleep;
the plugin promises only `/workspace`.

Back to the [README](../README.md).
