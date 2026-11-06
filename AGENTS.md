# rzv-claude-plugin agent guide

Runzivo-wide rules: [rzv-business/operating-policy.md](https://github.com/Runzivo/rzv-business/blob/main/operating-policy.md) (local checkout: ../rzv-business/operating-policy.md). This file adds only plugin guidance.

- The plugin only calls the `rzv` CLI through `scripts/runzivo.sh`. Sandbox lifecycle logic belongs in `rzv` in Runzivo/rzv-cli, not here.
- No hooks, MCP servers, monitors or top-level `bin/` unless a plain CLI wrapper cannot do the job; each needs a note in docs/privacy.md.
- Skills that change cost or delete data keep `disable-model-invocation: true`.
- Run the checks in docs/testing.md before every merge, and the live test before a tag. Raise `version` in `.claude-plugin/plugin.json` for every release.
- The repository is public: no internal hostnames, inventory, secrets or unreleased plans.
