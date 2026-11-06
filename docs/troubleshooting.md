# Troubleshooting

Claude shows the `rzv` error and the next step. `rzv --version` and
`rzv whoami` show which CLI you have and who is signed in.

| Message | What to do |
| - | - |
| `rzv: command not found` | `curl -fsSL https://runzivo.dev/downloads/rzv/install.sh \| sh` |
| Unknown command or flag | `rzv --version`; below 0.26.0, install again with the command above |
| Sign in with `rzv login` | Run `rzv login` in a terminal; it opens your browser |
| `credit_exhausted` | Add credit in the Runzivo portal, under Billing |
| `sandbox_limit_reached` | Sleep or delete a running sandbox, then retry |
| `sandbox_capacity_busy`, `no_capacity` | Wait a few minutes, or pick a smaller size |
| `plan_required`, `size_unavailable` | Pick a size from `rzv sandboxes sizes` |
| `sandbox_expired` | The lifetime ended; create a new sandbox |
| `sandbox_wrong_state` | It is starting or stopping; check status shortly |
| SSH still starting | Run `/runzivo:connect <id>` again in a minute |
| Claude keeps asking to run `rzv` | Approve it, or allow `Bash(rzv *)` in `/permissions` |

## SSH

- `ssh <id>.rzv` fails with an unknown host: run `/runzivo:connect <id>`.
- Host key or certificate errors: `rzv sandboxes ssh <id>` reports the cause.
- No OpenSSH (some Windows setups): `rzv sandboxes terminal <id>` opens a shell.

## Several Runzivo accounts

`rzv` uses its active profile. To use another, start Claude Code with
`RZV_PROFILE=<profile>` set, or switch with `rzv profiles use <profile>`.

Back to the [README](../README.md).
