#!/usr/bin/env bash
export HOOK_INPUT=$(cat)

python3 << 'PYEOF'
import os, json, re, sys

raw = os.environ.get('HOOK_INPUT', '{}')

# Próba parsowania JSON
cmd = ''
try:
    data = json.loads(raw)
    cmd = data.get('tool_input', {}).get('command', '')
except Exception:
    # JSON niepoprawny (np. surowe newline) - szukaj w surowym stringu
    # Wyciągnij wartość "command" regexem
    m = re.search(r'"command"\s*:\s*"((?:[^"\\]|\\.)*)"', raw, re.DOTALL)
    if m:
        cmd = m.group(1)
        # Odkoduj escape sequences
        cmd = cmd.replace('\\n', '\n').replace('\\"', '"').replace('\\\\', '\\')
    else:
        cmd = raw  # ostateczny fallback - szukaj w całości

if not cmd:
    sys.exit(0)

# Nie dotyczy sqlite — przepuść
if not re.search(r'(sqlite3|import sqlite3|\.connect\s*\()', cmd):
    sys.exit(0)

WRITE_OPS = re.compile(
    r'\b(insert|update|delete|drop|truncate|alter|create|replace|upsert)\b',
    re.IGNORECASE
)
PRAGMA_WRITE = re.compile(r'pragma\s+\w+\s*=', re.IGNORECASE)
EXTERNAL_SQL = re.compile(r'sqlite3\b.*(<\s*\S+|-init\s+\S+)', re.IGNORECASE)

m = WRITE_OPS.search(cmd)
if m:
    reason = f"SQLite write blocked — '{m.group(0).strip()}' not allowed in read-only mode"
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": reason
    }}))
    sys.exit(2)

if PRAGMA_WRITE.search(cmd):
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": "SQLite write blocked — PRAGMA write not allowed"
    }}))
    sys.exit(2)

if EXTERNAL_SQL.search(cmd):
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": "SQLite write blocked — external SQL file not allowed"
    }}))
    sys.exit(2)

sys.exit(0)
PYEOF