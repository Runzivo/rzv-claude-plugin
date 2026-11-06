#!/usr/bin/env bash
# Offline checks for the plugin folder: Anthropic directory file and tool
# rules, manifests, and the rzv commands each skill gives Claude. No network.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
exec python3 -I - "$root" <<'PY'
import json, os, re, sys

root = sys.argv[1]
plugin = os.path.join(root, "plugins", "runzivo")
failures = []

def check(name, ok, detail=""):
    print(("ok   " if ok else "FAIL ") + name + ("" if ok else ": " + detail))
    if not ok:
        failures.append(name)

# Directory policy: only these file types may sit in the plugin folder.
allowed_ext = {".md", ".txt", ".json", ".yaml", ".yml", ".png", ".jpg", ".jpeg", ".gif", ".webp", ".ico"}
allowed_names = {"LICENSE", "README", ".gitignore"}
bad = []
for d, dirs, files in os.walk(plugin):
    for f in files:
        p = os.path.join(d, f)
        if os.path.islink(p) or not (f in allowed_names or os.path.splitext(f)[1].lower() in allowed_ext):
            bad.append(os.path.relpath(p, plugin))
check("plugin folder holds only allowed file types", not bad, ", ".join(bad))
for extra in ("hooks", "bin", "scripts", ".mcp.json", "agents", "commands"):
    check(f"no {extra} in the plugin", not os.path.exists(os.path.join(plugin, extra)))

# Manifests.
p = json.load(open(os.path.join(plugin, ".claude-plugin", "plugin.json")))
m = json.load(open(os.path.join(root, ".claude-plugin", "marketplace.json")))
check("marketplace lists only runzivo", [e["name"] for e in m["plugins"]] == [p["name"]] == ["runzivo"])
check("marketplace source is ./plugins/runzivo", m["plugins"][0]["source"] == "./plugins/runzivo")
check("plugin.json has no tool, hook or server fields", not {"hooks", "mcpServers", "commands", "agents"} & set(p))
changelog = open(os.path.join(root, "CHANGELOG.md")).read()
top = re.search(r"^## (\S+)", changelog, re.M)
check("CHANGELOG top section matches the version", bool(top) and top.group(1) == p.get("version"), f"{top and top.group(1)} vs {p.get('version')}")
check("icon is in the plugin", os.path.isfile(os.path.join(plugin, p["icon"])))

skills = {}
for name in sorted(os.listdir(os.path.join(plugin, "skills"))):
    text = open(os.path.join(plugin, "skills", name, "SKILL.md")).read()
    fm = re.match(r"---\n(.*?)\n---\n", text, re.S)
    check(f"{name}: has frontmatter", bool(fm))
    skills[name] = (fm.group(1) if fm else "", text)

check("the seven skills", sorted(skills) == ["connect", "create", "delete", "sandbox", "sleep", "status", "wake"], str(sorted(skills)))
for name, (fm, text) in skills.items():
    tools = re.search(r"^allowed-tools:(.*)$", fm, re.M)
    granted = re.findall(r"[^\s,]+", tools.group(1)) if tools else []
    check(f"{name}: allowed-tools only Read, Grep, Glob, LS", set(granted) <= {"Read", "Grep", "Glob", "LS"}, str(granted))
    check(f"{name}: no plugin-root paths", "${" not in text, "contains ${...}")
    check(f"{name}: tells how to install rzv", "runzivo.dev/downloads/rzv/install.sh | sh" in text)
    for code in ("authentication_required", "credit_exhausted", "sandbox_capacity_busy", "sandbox_limit_reached"):
        check(f"{name}: explains {code}", code in text)
    costly = name in ("create", "sleep", "wake", "delete")
    check(f"{name}: disable-model-invocation is {costly}", ("disable-model-invocation: true" in fm) == costly)

def has(name, *needles):
    text = skills[name][1]
    missing = [n for n in needles if n not in text]
    check(f"{name}: gives {', '.join(needles)}", not missing, "missing " + ", ".join(missing))

has("create", "rzv sandboxes create --name claude-<slug>", "--size", "--lifetime", "--disk-gib", "rzv sandboxes ssh-config <id> --write", "Never retry a create")
has("connect", "rzv sandboxes ssh-config <id> --write", "ssh <id>.rzv")
has("status", "rzv sandboxes list --json", "rzv sandboxes get <id> --json", "remaining_seconds", "expires_at", "credits_used")
has("sleep", "rzv sandboxes stop <id> --json")
has("wake", "rzv sandboxes start <id> --json", "rzv sandboxes ssh-config <id> --write")
has("delete", "--yes", "ask the user to confirm and stop here", "rzv sandboxes delete <id> --json", "rm -f ~/.ssh/rzv/<id>.conf")
has("sandbox", "ssh <id>.rzv 'cd /workspace", "Never create, wake, sleep or delete", "mode 600")

if failures:
    print(f"{len(failures)} failed")
    sys.exit(1)
print("all tests passed")
PY
