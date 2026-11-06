#!/usr/bin/env bash
# Live end-to-end test: drive the plugin's slash commands through `claude -p`
# against a Runzivo test environment, and check each step with rzv directly.
# The plugin grants no tools, so this test (and only this test) pre-approves
# the commands the skills run with --allowedTools; a user approves each one.
#
#   RZV_PROFILE=<profile> E2E_EVIDENCE=<dir> [E2E_LOCK=<dir>] scripts/20-shared-e2e.sh
#
# It aborts unless `rzv whoami` reports the environment in E2E_ENVIRONMENT
# (default: shared). It creates one sandbox and deletes it, even on failure.
# E2E_LOCK, when set, is a directory used as a lock (mkdir) so test runs that
# share a workspace take turns; it holds an owner file while the test runs.
# Evidence holds command output, never tokens.
set -euo pipefail

here=$(cd "$(dirname "$0")/.." && pwd)
plugin="$here/plugins/runzivo"
claude_bin=$(command -v claude) || { echo "claude is not on PATH" >&2; exit 1; }
evidence=${E2E_EVIDENCE:?set E2E_EVIDENCE to an evidence directory}
environment=${E2E_ENVIRONMENT:-shared}
model=${E2E_MODEL:-claude-haiku-5-5}
rzv=${RZV_BIN:-$(command -v rzv)} || { echo "rzv is not on PATH" >&2; exit 1; }
mkdir -p "$evidence"
name="e2e-$(date -u +%m%d-%H%M%S)"
sandbox=""
locked=""
nohome=""
log() { printf '%s %s\n' "$(date -u +%H:%M:%S)" "$*" | tee -a "$evidence/log.txt" >&2; }
fail() { log "FAIL: $*"; exit 1; }

find_sandbox() {
  "$rzv" sandboxes list --json | python3 -I -c 'import json,sys
for s in json.load(sys.stdin)["sandboxes"]:
    if s["name"] == sys.argv[1] and s["status"] != "deleted": print(s["id"])' "claude-$name"
}

cleanup() {
  status=$?
  # A create that failed half-way still leaves a sandbox: find it by name.
  [ -n "$sandbox" ] || sandbox=$(find_sandbox 2>/dev/null || true)
  if [ -n "$sandbox" ]; then
    log "cleanup: deleting $sandbox"
    "$rzv" sandboxes delete "$sandbox" --json >/dev/null 2>&1 || true
    rm -f "$HOME/.ssh/rzv/$sandbox.conf"
  fi
  if [ -n "$locked" ]; then rm -f "$E2E_LOCK/owner"; rmdir "$E2E_LOCK" || log "could not remove lock $E2E_LOCK"; fi
  [ -z "$nohome" ] || rm -rf "$nohome"
  if [ "$status" -eq 0 ]; then log "PASS"; else log "exit $status"; fi
  log "evidence: $evidence"
}
trap cleanup EXIT

# Keep only the environment line; the rest of whoami names the account.
"$rzv" whoami 2>&1 | grep "^Environment:" > "$evidence/environment.txt" || fail "rzv is not signed in"
grep -q "^Environment: $environment " "$evidence/environment.txt" || fail "rzv is not on the $environment environment"

if [ -n "${E2E_LOCK:-}" ]; then
  deadline=$((SECONDS + ${E2E_LOCK_WAIT:-3600}))
  until mkdir "$E2E_LOCK" 2>/dev/null; do
    [ "$SECONDS" -lt "$deadline" ] || fail "lock $E2E_LOCK still held; remove it if no test is running"
    log "waiting for lock $E2E_LOCK"
    sleep 15
  done
  locked=1
  printf 'rzv-claude-plugin e2e, pid %s, since %s\n' "$$" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$E2E_LOCK/owner"
fi

# Test-only approvals for the commands the skills tell Claude to run.
allow=(--allowedTools "Bash(rzv *)" "Bash(ssh *)" "Bash(date *)" "Bash(sleep *)" "Bash(sleep 10 && rzv sandboxes get *)" "Bash(head -n 1 ~/.ssh/rzv/*)" "Bash(head -n 1 $HOME/.ssh/rzv/*)" "Bash(rm -f ~/.ssh/rzv/*)" "Bash(rm -f $HOME/.ssh/rzv/*)" "Bash(~/.local/bin/rzv *)" "Bash(command -v *)" "Bash(which *)" "Bash(ls *)")

# turn <label> <prompt> [extra claude flags]: one claude -p turn with the plugin.
turn() {
  local label=$1 prompt=$2
  shift 2
  log "claude -p: $prompt"
  # The prompt goes on stdin: --allowedTools takes several values and would
  # swallow a prompt argument after it.
  printf '%s' "$prompt" | "$claude_bin" -p --plugin-dir "$plugin" --model "$model" --output-format json "${allow[@]}" "$@" \
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
# Claude's tool shell gets no rzv on PATH and an empty home, so
# ~/.local/bin/rzv is missing too. claude itself keeps its own sign-in.
nohome=$(mktemp -d "$evidence/nohome.XXXXXX")
case "$nohome" in *[\"\\]*) fail "E2E_EVIDENCE must not contain quotes or backslashes" ;; esac
turn err-no-rzv "/runzivo:status" --settings "{\"env\":{\"HOME\":\"$nohome\",\"PATH\":\"/usr/bin:/bin\"}}"
grep -q "install.sh" "$evidence/err-no-rzv.txt" || fail "no install hint without rzv"
RZV_PROFILE="e2e-no-such-profile-$$" turn err-signed-out "/runzivo:status"
grep -q "rzv login" "$evidence/err-signed-out.txt" || fail "no sign-in hint when signed out"

log "2. create claude-$name"
turn create "/runzivo:create $name"
sandbox=$(find_sandbox)
[ -n "$sandbox" ] || fail "no sandbox named claude-$name"
log "sandbox $sandbox"
wait_status running
grep -q "$sandbox.rzv" "$evidence/create.txt" || fail "create did not print the ssh alias"
grep -q "^# Managed by rzv" "$HOME/.ssh/rzv/$sandbox.conf" || fail "no ssh alias"

log "3. a task in the sandbox over SSH, through the sandbox skill"
turn task "/runzivo:sandbox $sandbox Run uname -sm and write the word hello to /workspace/e2e.txt in the sandbox."
[ "$(ssh "$sandbox.rzv" cat /workspace/e2e.txt)" = hello ] || fail "the task did not write /workspace/e2e.txt"
ssh "$sandbox.rzv" uname -sm | tee -a "$evidence/log.txt" >&2

log "4. status and metering"
sleep 60
turn status "/runzivo:status $sandbox"
credits=$(get "$sandbox" credits_used)
log "credits_used $credits, remaining_seconds $(get "$sandbox" remaining_seconds), expires_at $(get "$sandbox" expires_at)"
python3 -I -c 'import sys; sys.exit(0 if float(sys.argv[1]) > 0 else 1)' "$credits" || fail "no credits metered"

ssh "$sandbox.rzv" 'echo kept > ~/e2e-home.txt'

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
# Recorded, not required: the plugin promises only /workspace.
log "home directory after wake: $(ssh "$sandbox.rzv" 'cat ~/e2e-home.txt 2>/dev/null || echo reset')"

log "7. delete with confirmation"
turn delete-ask "/runzivo:delete $sandbox"
[ "$(get "$sandbox" status)" = running ] || fail "delete ran without confirmation"
turn delete "/runzivo:delete $sandbox --yes"
status=$(get "$sandbox" status)
case "$status" in deleting | deleted) ;; *) fail "status after delete is $status" ;; esac
[ ! -e "$HOME/.ssh/rzv/$sandbox.conf" ] || fail "ssh alias left behind"
sandbox=""
