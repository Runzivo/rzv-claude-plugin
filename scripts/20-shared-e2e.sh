#!/usr/bin/env bash
# Live end-to-end test: drive the plugin's slash commands through `claude -p`
# against a Runzivo test environment, and check each step with rzv directly.
#
#   RZV_PROFILE=<profile> E2E_EVIDENCE=<dir> [E2E_LOCK=<dir>] scripts/20-shared-e2e.sh
#
# It aborts unless `rzv whoami` reports the environment in E2E_ENVIRONMENT
# (default: shared). It creates one sandbox and deletes it, even on failure.
# E2E_LOCK, when set, is a directory used as a lock (mkdir) so test runs that
# share a workspace take turns. Evidence holds command output, never tokens.
set -euo pipefail

here=$(cd "$(dirname "$0")/.." && pwd)
evidence=${E2E_EVIDENCE:?set E2E_EVIDENCE to an evidence directory}
environment=${E2E_ENVIRONMENT:-shared}
model=${E2E_MODEL:-claude-haiku-5-5}
rzv=${RZV_BIN:-$(command -v rzv)}
mkdir -p "$evidence"
name="e2e-$(date -u +%m%d-%H%M%S)"
sandbox=""
locked=""
log() { printf '%s %s\n' "$(date -u +%H:%M:%S)" "$*" | tee -a "$evidence/log.txt" >&2; }
fail() { log "FAIL: $*"; exit 1; }

cleanup() {
  status=$?
  if [ -n "$sandbox" ]; then
    log "cleanup: deleting $sandbox"
    "$rzv" sandboxes delete "$sandbox" --json >/dev/null 2>&1 || true
    rm -f "$HOME/.ssh/rzv/$sandbox.conf"
  fi
  [ -n "$locked" ] && rmdir "$E2E_LOCK"
  if [ "$status" -eq 0 ]; then log "PASS"; else log "exit $status"; fi
  log "evidence: $evidence"
}
trap cleanup EXIT

"$rzv" whoami > "$evidence/whoami.txt" 2>&1 || fail "rzv is not signed in"
grep -q "^Environment: $environment " "$evidence/whoami.txt" || fail "rzv is not on the $environment environment"
# Keep only the environment line; the rest names the account.
grep "^Environment:" "$evidence/whoami.txt" > "$evidence/environment.txt"
rm -f "$evidence/whoami.txt"

if [ -n "${E2E_LOCK:-}" ]; then
  until mkdir "$E2E_LOCK" 2>/dev/null; do log "waiting for lock $E2E_LOCK"; sleep 15; done
  locked=1
fi

# turn <label> <prompt> [extra claude flags]: one claude -p turn with the plugin.
turn() {
  local label=$1 prompt=$2
  shift 2
  log "claude -p: $prompt"
  claude -p --plugin-dir "$here" --model "$model" --output-format json "$@" "$prompt" \
    > "$evidence/$label.json" 2> "$evidence/$label.err" || fail "claude -p failed for $label"
  python3 -I - "$evidence/$label.json" <<'PY' | tee "$evidence/$label.txt" >&2
import json, sys
d = json.load(open(sys.argv[1]))
print(d.get("result", ""))
if d.get("permission_denials"):
    print("PERMISSION DENIALS:", json.dumps(d["permission_denials"]))
    sys.exit(1)
PY
}
get() { "$rzv" sandboxes get "$1" --json | python3 -I -c 'import json,sys; s=json.load(sys.stdin)["sandbox"]; print(s[sys.argv[1]])' "$2"; }
wait_status() {
  local want=$1 _
  for _ in $(seq 1 60); do
    [ "$(get "$sandbox" status)" = "$want" ] && return 0
    sleep 5
  done
  fail "$sandbox did not reach $want"
}

log "1. errors: no rzv, not signed in"
RZV_BIN="$evidence/no-such-rzv" turn err-no-rzv "/runzivo:status"
grep -q "install.sh" "$evidence/err-no-rzv.txt" || fail "no install hint without rzv"
RZV_PROFILE="e2e-no-such-profile-$$" turn err-signed-out "/runzivo:status"
grep -q "rzv login" "$evidence/err-signed-out.txt" || fail "no sign-in hint when signed out"

log "2. create claude-$name"
turn create "/runzivo:create $name"
sandbox=$("$rzv" sandboxes list --json | python3 -I -c 'import json,sys
for s in json.load(sys.stdin)["sandboxes"]:
    if s["name"] == sys.argv[1] and s["status"] != "deleted": print(s["id"])' "claude-$name")
[ -n "$sandbox" ] || fail "no sandbox named claude-$name"
log "sandbox $sandbox"
wait_status running
grep -q "$sandbox.rzv" "$evidence/create.txt" || fail "create did not print the ssh alias"
grep -q "^# Managed by rzv" "$HOME/.ssh/rzv/$sandbox.conf" || fail "no ssh alias"

log "3. a task in the sandbox over SSH, through the sandbox skill"
turn task "/runzivo:sandbox $sandbox Run uname -sm and write the word hello to /workspace/e2e.txt in the sandbox." --allowedTools "Bash(ssh *)"
[ "$(ssh "$sandbox.rzv" cat /workspace/e2e.txt)" = hello ] || fail "the task did not write /workspace/e2e.txt"
ssh "$sandbox.rzv" uname -sm | tee -a "$evidence/log.txt" >&2

log "4. status and metering"
sleep 60
turn status "/runzivo:status $sandbox"
credits=$(get "$sandbox" credits_used)
log "credits_used $credits, remaining_seconds $(get "$sandbox" remaining_seconds), expires_at $(get "$sandbox" expires_at)"
python3 -I -c 'import sys; sys.exit(0 if float(sys.argv[1]) > 0 else 1)' "$credits" || fail "no credits metered"

log "5. sleep"
turn sleep "/runzivo:sleep $sandbox"
wait_status stopped
before=$(get "$sandbox" credits_used)
sleep 30
[ "$(get "$sandbox" credits_used)" = "$before" ] || fail "credits grew while asleep"

log "6. wake and reconnect"
turn wake "/runzivo:wake $sandbox"
wait_status running
[ "$(ssh "$sandbox.rzv" cat /workspace/e2e.txt)" = hello ] || fail "/workspace did not survive sleep"

log "7. delete with confirmation"
turn delete-ask "/runzivo:delete $sandbox"
[ "$(get "$sandbox" status)" = running ] || fail "delete ran without confirmation"
turn delete "/runzivo:delete $sandbox --yes"
status=$(get "$sandbox" status)
case "$status" in deleting | deleted) ;; *) fail "status after delete is $status" ;; esac
[ ! -e "$HOME/.ssh/rzv/$sandbox.conf" ] || fail "ssh alias left behind"
sandbox=""
