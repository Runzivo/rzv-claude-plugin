# Changelog

## 0.2.1 (2026-11-06)

- Skills point to https://runzivo.dev/docs/cli/ to install `rzv` instead of
  showing a `curl | sh` command, which the plugin directory flags as an
  install-time risk.

## 0.2.0 (2026-11-06)

- The plugin now lives in `plugins/runzivo/`, which holds only Markdown, JSON,
  the icon and the licence, as Anthropic's directory requires. The repository
  root stays the `runzivo` marketplace; install with the same commands.
- Skills are instructions only. Claude runs `rzv` commands itself, and you
  approve each one: the plugin no longer ships `scripts/runzivo.sh` or grants
  any tools. `RZV_BIN` is no longer read; `rzv` comes from PATH or
  `~/.local/bin`.
- `/runzivo:delete` still deletes only after you confirm or pass `--yes`.

## 0.1.0 (2026-11-06)

- First release: `/runzivo:create`, `connect`, `status`, `sleep`, `wake` and
  `delete` slash commands, and the `sandbox` skill for running work over SSH.
- Works with `rzv` 0.26.0 or later. The repository is also the `runzivo`
  marketplace: `claude plugin install runzivo@runzivo`.
