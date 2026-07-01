#!/usr/bin/env bash
# scope-staleness.sh — detect when a directory has drifted from its scope-init AGENTS.md.
#
# A directory's "shape hash" is derived from git's per-file blob SHAs of its
# *direct* tracked files (AGENTS.md excluded). `scope-init` records this hash in
# the manifest whenever it (re)writes an AGENTS.md. The pre-commit hook recomputes
# the hash from the staged index and compares: a mismatch means the directory
# changed since its AGENTS.md was generated, so the doc may be stale.
#
# Computing the hash costs ~nothing: git already stores a content (blob) SHA for
# every tracked file, so no file contents are read. The hash exists only to gate
# the expensive part — re-running the /scope-init LLM skill — which a human/agent
# does after seeing a warning. This script never invokes an LLM.
#
# Usage:
#   scope-staleness.sh check  [--staged]    # check every manifest dir; exit 1 if any stale
#   scope-staleness.sh write  <dir>         # record <dir>'s current worktree hash
#   scope-staleness.sh hash   <dir> [--staged]   # print one dir's hash and exit
#
# Hook bypass: SCOPE_STALENESS_BLOCK=0 downgrades `check` to warn-only (exit 0).
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
MANIFEST=".claude/scope-init.lock.json"

# dir_hash <dir> <worktree|staged> -> 12-hex shape hash of the dir's direct files
dir_hash() {
  local dir="${1%/}" mode="$2" rel
  {
    if [ "$mode" = staged ]; then
      # blob SHAs straight from the index: "<mode> <sha> <stage>\t<path>"
      git ls-files -s -- "$dir/" | while read -r _m sha _s path; do
        rel="${path:$((${#dir}+1))}"
        case "$rel" in */*|AGENTS.md) continue ;; esac
        printf '%s %s\n' "$path" "$sha"
      done
    else
      # blob SHA of current worktree content
      git ls-files -- "$dir/" | while read -r path; do
        rel="${path:$((${#dir}+1))}"
        case "$rel" in */*|AGENTS.md) continue ;; esac
        printf '%s %s\n' "$path" "$(git hash-object "$path")"
      done
    fi
  } | LC_ALL=C sort | sha256sum | cut -c1-12
}

cmd_write() {
  local dir="${1%/}"
  [ -n "$dir" ] || { echo "usage: scope-staleness.sh write <dir>" >&2; exit 2; }
  [ -f "$dir/AGENTS.md" ] || echo "note: $dir/AGENTS.md not found (recording hash anyway)" >&2
  local h; h="$(dir_hash "$dir" worktree)"
  MANIFEST="$MANIFEST" python3 - "$dir" "$h" <<'PY'
import json, os, sys
m = os.environ["MANIFEST"]
d, h = sys.argv[1], sys.argv[2]
data = {"version": 1, "dirs": {}}
if os.path.exists(m):
    with open(m) as f:
        data = json.load(f)
data.setdefault("dirs", {})[d] = h
with open(m, "w") as f:
    json.dump(data, f, indent=2, sort_keys=True)
    f.write("\n")
PY
  echo "recorded $dir -> $h in $MANIFEST"
}

cmd_check() {
  local mode=worktree
  [ "${1:-}" = "--staged" ] && mode=staged
  if [ ! -f "$MANIFEST" ]; then
    echo "no manifest ($MANIFEST) — nothing to check"
    return 0
  fi
  local stale=0 dir want got
  while read -r dir want; do
    if [ ! -d "$dir" ]; then
      echo "⚠ $dir/ is in the manifest but the directory is gone — drop it or re-run /scope-init"
      stale=1; continue
    fi
    got="$(dir_hash "$dir" "$mode")"
    if [ "$got" != "$want" ]; then
      echo "⚠ $dir/ changed since its AGENTS.md was generated ($want → $got)"
      echo "    → re-run:  /scope-init $dir"
      stale=1
    fi
  done < <(MANIFEST="$MANIFEST" python3 -c 'import json,os;[print(k,v) for k,v in json.load(open(os.environ["MANIFEST"]))["dirs"].items()]')
  if [ "$stale" -ne 0 ] && [ "${SCOPE_STALENESS_BLOCK:-1}" = "0" ]; then
    echo "(SCOPE_STALENESS_BLOCK=0 — warning only, not blocking)"
    return 0
  fi
  return "$stale"
}

cmd_hash() {
  local dir="${1%/}" mode=worktree
  [ "${2:-}" = "--staged" ] && mode=staged
  [ -n "$dir" ] || { echo "usage: scope-staleness.sh hash <dir> [--staged]" >&2; exit 2; }
  dir_hash "$dir" "$mode"
}

case "${1:-}" in
  check) shift; cmd_check "$@" ;;
  write) shift; cmd_write "$@" ;;
  hash)  shift; cmd_hash  "$@" ;;
  *) echo "usage: scope-staleness.sh {check [--staged]|write <dir>|hash <dir> [--staged]}" >&2; exit 2 ;;
esac
