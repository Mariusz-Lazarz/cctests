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
#   scope-staleness.sh check    [--staged]  # check every manifest dir; exit 1 if any stale
#   scope-staleness.sh write    <dir>       # record <dir>'s current worktree hash
#   scope-staleness.sh hash     <dir> [--staged]  # print one dir's hash and exit
#   scope-staleness.sh discover             # list tracked dirs that look worth scoping
#                                           #   but have no AGENTS.md (informational; exit 0)
#   scope-staleness.sh ignore   <dir>       # mark <dir> as never-a-candidate for discover
#
# Hook bypass: SCOPE_STALENESS_BLOCK=0 downgrades `check` to warn-only (exit 0).
# Discovery tuning: SCOPE_DISCOVER_MIN (default 2) = min files of the dominant
# extension a dir needs before it's flagged as a scope-init candidate.
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

# cmd_discover — find tracked dirs that look like scope-init candidates but have no
# AGENTS.md yet. Uses only `git ls-files` (no file contents read), so it's as cheap as
# `check`. A dir qualifies when it has >= SCOPE_DISCOVER_MIN direct files sharing a
# dominant extension, no AGENTS.md/CLAUDE.md of its own, and isn't already tracked
# (manifest .dirs) or suppressed (manifest .ignore). Prints "<dir>\t<count>\t<ext>" per
# candidate; always exits 0 — surfacing is the caller's job. This mirrors the bar
# /scope-init itself uses (>=2 consistent siblings), so it never flags what the skill
# would refuse to document.
cmd_discover() {
  MANIFEST="$MANIFEST" MIN="${SCOPE_DISCOVER_MIN:-2}" python3 - <<'PY'
import json, os, subprocess
from collections import defaultdict, Counter

MIN = int(os.environ.get("MIN", "2"))
manifest = os.environ["MANIFEST"]
data = json.load(open(manifest)) if os.path.exists(manifest) else {}
skip = set(data.get("dirs", {})) | set(data.get("ignore", []))

# Never candidates: VCS/dep/build/generated trees and any dotted path segment.
EXCLUDE = {".git", "node_modules", "scripts", "graphify-out",
           "dist", "build", "__pycache__", "venv"}

direct = defaultdict(list)   # dir -> [filename, ...]  (direct children only)
documented = set()           # dirs that already carry an AGENTS.md/CLAUDE.md

tracked = subprocess.run(["git", "ls-files"], capture_output=True, text=True,
                         check=True).stdout.splitlines()
for path in tracked:
    d, _, name = path.rpartition("/")
    if not d:
        continue  # repo-root files: the root is out of scope for /scope-init
    if any(p in EXCLUDE or p.startswith(".") for p in d.split("/")):
        continue
    if name in ("AGENTS.md", "CLAUDE.md"):
        documented.add(d)
    else:
        direct[d].append(name)

out = []
for d, names in direct.items():
    if d in skip or d in documented:
        continue
    exts = Counter(e for n in names if (e := os.path.splitext(n)[1]))
    if not exts:
        continue
    ext, cnt = exts.most_common(1)[0]
    if cnt >= MIN:
        out.append((d, cnt, ext))

for d, cnt, ext in sorted(out):
    print(f"{d}\t{cnt}\t{ext}")
PY
}

cmd_ignore() {
  local dir="${1%/}"
  [ -n "$dir" ] || { echo "usage: scope-staleness.sh ignore <dir>" >&2; exit 2; }
  MANIFEST="$MANIFEST" python3 - "$dir" <<'PY'
import json, os, sys
m = os.environ["MANIFEST"]
d = sys.argv[1]
data = {"version": 1, "dirs": {}}
if os.path.exists(m):
    data = json.load(open(m))
ig = set(data.get("ignore", []))
ig.add(d)
data["ignore"] = sorted(ig)
with open(m, "w") as f:
    json.dump(data, f, indent=2, sort_keys=True)
    f.write("\n")
PY
  echo "ignoring $dir for discovery (recorded in $MANIFEST)"
}

case "${1:-}" in
  check)    shift; cmd_check    "$@" ;;
  write)    shift; cmd_write    "$@" ;;
  hash)     shift; cmd_hash     "$@" ;;
  discover) shift; cmd_discover "$@" ;;
  ignore)   shift; cmd_ignore   "$@" ;;
  *) echo "usage: scope-staleness.sh {check [--staged]|write <dir>|hash <dir> [--staged]|discover|ignore <dir>}" >&2; exit 2 ;;
esac
