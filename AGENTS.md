# rzv-claude-plugin agent guide

Runzivo-wide rules: [rzv-business/operating-policy.md](https://github.com/Runzivo/rzv-business/blob/main/operating-policy.md) (local checkout: ../rzv-business/operating-policy.md). This file adds only plugin guidance.

- The plugin is `plugins/runzivo/`. Anthropic's directory allows only Markdown, text, JSON, YAML, images, LICENSE, README and .gitignore there, and `allowed-tools` may hold only Read, Grep, Glob and LS. Tests, scripts and the demo stay outside it. `tests/run.sh` enforces this.
- Skills are instructions that name the exact `rzv` command to run. Sandbox lifecycle logic belongs in `rzv` in Runzivo/rzv-cli, not here.
- No hooks, MCP servers, monitors or `bin/`.
- Skills that change cost or delete data keep `disable-model-invocation: true`.
- Run the checks in docs/testing.md before every merge, and the live test before a tag. Raise `version` in `plugins/runzivo/.claude-plugin/plugin.json` for every release.
- The repository is public: no internal hostnames, inventory, secrets or unreleased plans.
