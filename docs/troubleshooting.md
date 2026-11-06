# Troubleshooting

Every failure ends with a "Next step" line. `scripts/runzivo.sh doctor` shows
which `rzv` the plugin uses and who is signed in.

| Message | What to do |
| - | - |
| `rzv` was not found | `curl -fsSL https://runzivo.dev/downloads/rzv/install.sh \| sh`, or set `RZV_BIN` |
| rzv ... is too old | Install again with the command above (0.26.0 or later) |
| Sign in with `rzv login` | Run `rzv login` in a terminal; it opens your browser |
| `credit_exhausted` | Add credit in the Runzivo portal, under Billing |
| `sandbox_limit_reached` | Sleep or delete a running sandbox, then retry |
| `sandbox_capacity_busy`, `no_capacity` | Wait a few minutes, or pick a smaller size |
| `plan_required`, `size_unavailable` | Pick a size from `rzv sandboxes sizes` |
| `sandbox_expired` | The lifetime ended; create a new sandbox |
| `sandbox_wrong_state` | It is starting or stopping; check status shortly |
| still starting | Run `/runzivo:connect <id>` again in a minute |

## SSH

- `ssh <id>.rzv` fails with an unknown host: run `/runzivo:connect <id>`.
- Host key or certificate errors: `rzv sandboxes ssh <id>` reports the cause.
- No OpenSSH (some Windows setups): `rzv sandboxes terminal <id>` opens a shell.

## Several Runzivo accounts

`rzv` uses its active profile. To use another, start Claude Code with
`RZV_PROFILE=<profile>` set, or switch with `rzv profiles use <profile>`.

Back to the [README](../README.md).
