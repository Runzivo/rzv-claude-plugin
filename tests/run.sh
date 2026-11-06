#!/usr/bin/env bash
# Offline tests for scripts/runzivo.sh against tests/fake-rzv. No network.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
script="$here/../scripts/runzivo.sh"
# TEST_BASH=/bin/bash runs the script under another bash, such as macOS bash 3.2.
shell=${TEST_BASH:-bash}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export HOME="$work/home" FAKE_STATE="$work/state" RZV_BIN="$here/fake-rzv" RUNZIVO_WAIT=10
mkdir -p "$HOME" "$FAKE_STATE"
failures=0
id=sbx_0123456789abcdef01234567

check() { # check <name> <expected exit> <expected text> -- command...
  local name=$1 want=$2 text=$3 out status
  shift 4
  out=$("$@" 2>&1)
  status=$?
  if [ "$status" -ne "$want" ] || { [ -n "$text" ] && ! printf '%s' "$out" | grep -qF -- "$text"; }; then
    printf 'FAIL %s (exit %s, want %s)\n%s\n' "$name" "$status" "$want" "$out"
    failures=$((failures + 1))
  else
    printf 'ok   %s\n' "$name"
  fi
}

check "create names claude-<slug> and connects" 0 "ssh $id.rzv" -- "$shell" "$script" create "My Project!" --lifetime 12h
check "create sent the name and lifetime" 0 "--name claude-my-project --lifetime 12h --json" -- cat "$FAKE_STATE/calls"
check "ssh alias written" 0 "Host $id.rzv" -- cat "$HOME/.ssh/rzv/$id.conf"
check "a name of several words" 0 "Created claude-my-big-project" -- "$shell" "$script" create my big project
check "long name has no trailing hyphen" 0 "Created claude-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa (" -- "$shell" "$script" create "$(printf 'a%.0s' $(seq 39))-b"
check "default name is a timestamp" 0 "Created claude-2" -- "$shell" "$script" create
check "bad size refused" 2 "--size must be" -- "$shell" "$script" create --size huge
check "bad lifetime refused" 2 "--lifetime must be" -- "$shell" "$script" create --lifetime 2h
check "bad disk refused" 2 "--disk-gib must be" -- "$shell" "$script" create --disk-gib 99
check "status hides deleted" 0 "$id a running" -- "$shell" "$script" status
check "status hides deleted (2)" 1 "" -- sh -c "'$shell' '$script' status | grep -q sbx_other"
check "status one sandbox" 0 "credits used: 1.5" -- "$shell" "$script" status "$id"
check "status of a missing sandbox fails" 6 "Not found in this workspace" -- env FAKE_ERROR=sandbox_not_found "$shell" "$script" status "$id"
check "failed sandbox shows its reason" 1 "out of credit" -- env FAKE_FAILED=credit_exhausted "$shell" "$script" connect "$id"
check "bad RUNZIVO_WAIT refused" 2 "RUNZIVO_WAIT must be" -- env RUNZIVO_WAIT=soon "$shell" "$script" connect "$id"
check "bad id refused" 2 "Give a sandbox id" -- "$shell" "$script" status "x; rm -rf /"
check "stop" 0 "/workspace is kept" -- "$shell" "$script" stop "$id"
check "connect while asleep" 1 "/runzivo:wake" -- "$shell" "$script" connect "$id"
check "start" 0 "Reconnect with /runzivo:connect" -- "$shell" "$script" start "$id"
check "delete needs --yes" 0 "NOT DELETED" -- "$shell" "$script" delete "$id"
check "delete did not call rzv delete" 1 "" -- grep -q "sandboxes delete" "$FAKE_STATE/calls"
check "delete --yes" 0 "Deleted $id" -- "$shell" "$script" delete "$id" --yes
check "delete removed the ssh alias" 1 "" -- test -e "$HOME/.ssh/rzv/$id.conf"
check "credit_exhausted hint" 1 "out of credit" -- env FAKE_ERROR=credit_exhausted "$shell" "$script" create
check "limit hint" 1 "maximum number of sandboxes" -- env FAKE_ERROR=sandbox_limit_reached "$shell" "$script" create
check "capacity hint" 1 "no free capacity" -- env FAKE_ERROR=sandbox_capacity_busy "$shell" "$script" create
check "not signed in hint" 3 "rzv login" -- env FAKE_ERROR=authentication_required "$shell" "$script" stop "$id"
check "old rzv refused" 1 "needs rzv 0.26.0" -- env FAKE_VERSION=0.25.9 "$shell" "$script" status
check "newer rzv accepted" 0 "Signed in" -- env FAKE_VERSION=0.100.0 "$shell" "$script" doctor
check "missing rzv" 127 "install.sh | sh" -- env RZV_BIN="$work/none" "$shell" "$script" status
check "no rzv anywhere" 127 "was not found" -- env -u RZV_BIN PATH=/usr/bin:/bin "$shell" "$script" status
check "unknown subcommand" 2 "Usage:" -- "$shell" "$script" exec "$id"

if [ "$failures" -ne 0 ]; then echo "$failures failed"; exit 1; fi
echo "all tests passed"
