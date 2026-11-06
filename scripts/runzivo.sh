#!/usr/bin/env bash
# runzivo.sh: the one program this plugin runs. It calls the Runzivo CLI (rzv)
# and nothing else: no network calls of its own, no tokens, no project files.
#
#   runzivo.sh doctor
#   runzivo.sh create [name] [--size S] [--lifetime 8h|12h|24h] [--disk-gib N]
#   runzivo.sh status [<sandbox-id>] [--json]
#   runzivo.sh connect <sandbox-id>
#   runzivo.sh stop|start <sandbox-id>
#   runzivo.sh delete <sandbox-id> [--yes]
set -uo pipefail

min_version=0.26.0
install_hint='Install it with: curl -fsSL https://runzivo.dev/downloads/rzv/install.sh | sh'
rzv=""

fail() {
  local code=$1
  shift
  printf 'runzivo: %s\n' "$*" >&2
  exit "$code"
}

# version_ge A B: true when version A >= B (major.minor.patch).
version_ge() {
  local IFS=. i x y
  local -a a b
  read -r -a a <<<"${1%%[-+ ]*}"
  read -r -a b <<<"$2"
  for i in 0 1 2; do
    x=${a[i]:-0}
    y=${b[i]:-0}
    case "$x$y" in *[!0-9]*) return 1 ;; esac
    if ((10#$x > 10#$y)); then return 0; fi
    if ((10#$x < 10#$y)); then return 1; fi
  done
  return 0
}

# Find rzv in RZV_BIN, then PATH, then ~/.local/bin, and check its version.
locate_rzv() {
  if [ -n "${RZV_BIN:-}" ]; then
    [ -f "$RZV_BIN" ] && [ -x "$RZV_BIN" ] || fail 127 "RZV_BIN ($RZV_BIN) is not an executable file. $install_hint"
    rzv=$RZV_BIN
  elif rzv=$(command -v rzv 2>/dev/null) && [ -n "$rzv" ]; then
    :
  elif [ -x "$HOME/.local/bin/rzv" ]; then
    rzv=$HOME/.local/bin/rzv
  else
    fail 127 "The Runzivo CLI (rzv) was not found in RZV_BIN, PATH or ~/.local/bin. $install_hint"
  fi
  local version
  version=$("$rzv" --version 2>/dev/null | awk 'NR==1 {print $2}')
  version_ge "${version:-0}" "$min_version" ||
    fail 1 "rzv ${version:-of unknown version} is too old; this plugin needs rzv $min_version or later. $install_hint"
}

# Print the next step for a failed rzv call, from its JSON error code.
# shellcheck disable=SC2016 # backticks are literal text in the hints
explain() {
  local status=$1 output=$2 code hint
  code=$(printf '%s' "$output" | sed -n 's/.*"error":"\([a-z0-9_]*\)".*/\1/p' | head -n 1)
  case "$code" in
    authentication_required | reauth_required) hint='Sign in with `rzv login` in a terminal (it opens your browser), then try again.' ;;
    credit_exhausted) hint='This workspace is out of credit. Add credit in the Runzivo portal (Billing), then try again.' ;;
    sandbox_limit_reached) hint='The workspace already runs its maximum number of sandboxes. Sleep or delete one (see /runzivo:status), then try again.' ;;
    sandbox_capacity_busy | no_capacity) hint='Runzivo has no free capacity right now. Wait a few minutes and try again, or choose a smaller size.' ;;
    sandbox_not_found | not_found) hint='No sandbox with that id in this workspace. /runzivo:status lists your sandboxes.' ;;
    sandbox_expired) hint='The sandbox reached the end of its lifetime. Create a new one with /runzivo:create.' ;;
    sandbox_wrong_state) hint='The sandbox is busy starting, stopping or deleting. Check /runzivo:status and try again shortly.' ;;
    sandbox_name_taken) hint='A sandbox with that name exists. Choose another name.' ;;
    plan_required | size_unavailable) hint='Choose a size your plan offers; `rzv sandboxes sizes` lists them.' ;;
    lifetime_unavailable) hint='That lifetime is not offered here. Leave it out to get 8h.' ;;
    customer_api_unavailable | service_unavailable | sandboxes_unavailable) hint='Runzivo is not reachable right now. Try again in a few minutes.' ;;
    access_denied | insufficient_role | permission_required | api_key_scope_required) hint='Your Runzivo role does not allow this. Ask a workspace owner, or pick another workspace with `rzv login --workspace`.' ;;
    workspace_blocked | workspace_closed) hint='This Runzivo workspace is blocked or closed. Contact Runzivo support.' ;;
    *) hint='' ;;
  esac
  if [ -z "$hint" ]; then
    case "$status" in
      3) hint='Sign in with `rzv login` in a terminal, then try again.' ;;
      4) hint='Your Runzivo account or role does not allow this. Check `rzv whoami`.' ;;
      5) hint='Runzivo is not reachable right now. Try again in a few minutes.' ;;
      6) hint='Not found in this workspace. /runzivo:status lists your sandboxes.' ;;
    esac
  fi
  printf 'runzivo: rzv failed (exit %s%s): %s\n' "$status" "${code:+, $code}" "$output" >&2
  [ -n "$hint" ] && printf 'Next step: %s\n' "$hint" >&2
  return "$status"
}

# rzv_json ARGS...: run rzv with --json; output on success, explain on failure.
# stdout and stderr are kept apart so a warning never mixes into the JSON.
rzv_json() {
  local output status errors errfile
  errfile=$(mktemp) || fail 1 "Could not create a temporary file."
  output=$("$rzv" "$@" --json 2>"$errfile")
  status=$?
  errors=$(cat "$errfile")
  rm -f "$errfile"
  if [ "$status" -ne 0 ]; then
    explain "$status" "$errors${output:+ $output}"
    return
  fi
  printf '%s\n' "$output"
}

need_id() {
  case "${1:-}" in
    sbx_[a-z0-9]*) case "$1" in *[!a-z0-9_]*) ;; *) return 0 ;; esac ;;
  esac
  fail 2 "Give a sandbox id such as sbx_0123456789abcdef01234567. /runzivo:status lists them."
}

field() { sed -n "s/.*\"$1\":\"\\([^\"]*\\)\".*/\\1/p" | head -n 1; }

# wait_running ID: wait until the sandbox runs (RUNZIVO_WAIT seconds, default 300).
wait_running() {
  local id=$1 wait=${RUNZIVO_WAIT:-300} deadline status json code
  case "$wait" in '' | *[!0-9]*) fail 2 "RUNZIVO_WAIT must be a number of seconds." ;; esac
  deadline=$((SECONDS + wait))
  while :; do
    json=$(rzv_json sandboxes get "$id") || return
    status=$(printf '%s' "$json" | field status)
    case "$status" in
      running) return 0 ;;
      pending | starting | creating | provisioning) ;;
      stopped) fail 1 "Sandbox $id is asleep. Wake it with /runzivo:wake $id first." ;;
      *)
        # A failed sandbox carries the reason, such as credit_exhausted.
        code=$(printf '%s' "$json" | sed -n 's/.*"error":{"code":"\([a-z0-9_]*\)".*/\1/p' | head -n 1)
        if [ -n "$code" ]; then
          explain 1 "{\"error\":\"$code\",\"message\":\"Sandbox $id is $status.\"}"
          return
        fi
        fail 1 "Sandbox $id is $status, so it cannot be connected to."
        ;;
    esac
    [ "$SECONDS" -ge "$deadline" ] && fail 1 "Sandbox $id is still $status. Run /runzivo:connect $id again in a minute."
    sleep 3
  done
}

connect() {
  local id=$1 output
  wait_running "$id" || return
  output=$("$rzv" sandboxes ssh-config "$id" --write 2>&1) || {
    explain $? "$output"
    return
  }
  cat <<EOF
Sandbox $id is running. SSH alias written: $id.rzv
  Shell:    ssh $id.rzv
  Run:      ssh $id.rzv 'cd /workspace && <command>'
  Copy:     rsync -a ./ $id.rzv:/workspace/<dir>/
  VS Code:  code --remote ssh-remote+$id.rzv /workspace
  Cursor:   cursor --remote ssh-remote+$id.rzv /workspace
/workspace is kept when the sandbox sleeps. Do not rely on anything else being kept.
EOF
}

create() {
  local slug="" size="" lifetime="" disk="" name json id
  local -a args=()
  while [ $# -gt 0 ]; do
    case "$1" in
      --size) size=${2:-}; shift 2 || fail 2 "--size needs a value" ;;
      --lifetime) lifetime=${2:-}; shift 2 || fail 2 "--lifetime needs a value" ;;
      --disk-gib) disk=${2:-}; shift 2 || fail 2 "--disk-gib needs a value" ;;
      -*) fail 2 "Unknown option $1. Use --size, --lifetime or --disk-gib." ;;
      *) slug="${slug:+$slug-}$1"; shift ;;
    esac
  done
  case "$size" in '' | 2vcpu-8gb | 4vcpu-16gb | 8vcpu-32gb | 16vcpu-64gb) ;; *) fail 2 "--size must be 2vcpu-8gb, 4vcpu-16gb, 8vcpu-32gb or 16vcpu-64gb." ;; esac
  case "$lifetime" in '' | 8h | 12h | 24h) ;; *) fail 2 "--lifetime must be 8h, 12h or 24h." ;; esac
  case "$disk" in '') ;; *[!0-9]*) fail 2 "--disk-gib must be a whole number from 5 to 64." ;; *) [ "$disk" -ge 5 ] && [ "$disk" -le 64 ] || fail 2 "--disk-gib must be a whole number from 5 to 64." ;; esac
  # Plugin sandboxes are named claude-<slug> so their usage can be counted.
  slug=$(printf '%s' "$slug" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9-' '-' | tr -s '-' | cut -c 1-40 | sed 's/^-//; s/-$//')
  slug=${slug#claude-}
  [ -n "$slug" ] || slug=$(date -u +%Y%m%d-%H%M%S)
  name="claude-$slug"
  args=(sandboxes create --name "$name")
  [ -n "$size" ] && args+=(--size "$size")
  [ -n "$lifetime" ] && args+=(--lifetime "$lifetime")
  [ -n "$disk" ] && args+=(--disk-gib "$disk")
  json=$(rzv_json "${args[@]}") || return
  printf '%s\n' "$json"
  id=$(printf '%s' "$json" | sed -n 's/.*"id":"\(sbx_[a-z0-9]*\)".*/\1/p' | head -n 1)
  [ -n "$id" ] || fail 1 "rzv did not return a sandbox id."
  echo "Created $name ($id). Waiting for it to start..."
  connect "$id"
}

status() {
  local id="" json=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --json) json=1 ;;
      *) id=$1 ;;
    esac
    shift
  done
  if [ -z "$id" ]; then
    if [ -n "$json" ]; then rzv_json sandboxes list; return; fi
    # Hide deleted sandboxes from the table; the header always stays.
    "$rzv" sandboxes list | awk 'NR == 1 || $0 !~ / deleted( |$)/' || explain $? "rzv sandboxes list failed"
    return
  fi
  need_id "$id"
  if [ -n "$json" ]; then rzv_json sandboxes get "$id"; return; fi
  "$rzv" sandboxes get "$id" || {
    explain $? "rzv sandboxes get failed"
    return
  }
  echo "Credits are equivalent minutes from your plan allowance or prepaid credit."
}

lifecycle() {
  local verb=$1 id=$2
  need_id "$id"
  rzv_json sandboxes "$verb" "$id" >/dev/null || return
  "$rzv" sandboxes get "$id" || {
    explain $? "rzv sandboxes get failed"
    return
  }
  if [ "$verb" = stop ]; then
    echo "Asleep: compute charges stop and /workspace is kept. Wake it with /runzivo:wake $id."
  else
    echo "Waking. Reconnect with /runzivo:connect $id. /workspace was kept."
  fi
}

delete() {
  local id=$1 confirm=${2:-} conf
  need_id "$id"
  if [ "$confirm" != --yes ]; then
    "$rzv" sandboxes get "$id" || {
      explain $? "rzv sandboxes get failed"
      return
    }
    echo "NOT DELETED. Deleting removes this sandbox and all its files for good."
    echo "Ask the user to confirm. Only the /runzivo:delete command may delete it."
    return 0
  fi
  rzv_json sandboxes delete "$id" || return
  # Remove the SSH alias that connect wrote, only if rzv owns the file.
  conf="$HOME/.ssh/rzv/$id.conf"
  if [ -f "$conf" ] && head -n 1 "$conf" | grep -q '^# Managed by rzv\.'; then
    rm -f "$conf"
  fi
  echo "Deleted $id."
}

doctor() {
  echo "rzv: $rzv"
  "$rzv" --version
  "$rzv" whoami || explain $? "rzv whoami failed"
}

main() {
  local sub=${1:-}
  [ $# -gt 0 ] && shift
  case "$sub" in
    doctor | create | status | connect | stop | start | delete) ;;
    *) fail 2 "Usage: runzivo.sh doctor|create|status|connect|stop|start|delete ..." ;;
  esac
  locate_rzv
  case "$sub" in
    doctor) doctor ;;
    create) create "$@" ;;
    status) status "$@" ;;
    connect) need_id "${1:-}"; connect "$1" ;;
    stop | start) lifecycle "$sub" "${1:-}" ;;
    delete) delete "${1:-}" "${2:-}" ;;
  esac
}

main "$@"
