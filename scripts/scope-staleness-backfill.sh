#!/usr/bin/env bash
#
# scope-staleness-backfill.sh — record shape hashes for area AGENTS.md dirs that
# don't have one yet, without touching dirs already baselined.
#
# Why: `scope-staleness.sh write <dir>` only records a hash when /scope-init runs
# on that dir. Repos that adopted the staleness gate late have older AGENTS.md
# files with no baseline in .claude/scope-init.lock.json. This backfills exactly
# those — the "only fill missing" semantics — so it never overwrites (and never
# masks drift on) a dir that already has a recorded hash.
#
# Usage:
#   scripts/scope-staleness-backfill.sh [--dry-run]
#
# Exit status: 0 on success (including "nothing to do"); non-zero on error.

set -euo pipefail

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
elif [[ -n "${1:-}" ]]; then
  echo "usage: $(basename "$0") [--dry-run]" >&2
  exit 2
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

WRITER="scripts/scope-staleness.sh"
LOCK=".claude/scope-init.lock.json"

if [[ ! -x "$WRITER" ]]; then
  echo "error: $WRITER not found or not executable (staleness gate not installed?)" >&2
  exit 1
fi

# Already-baselined dirs (repo-root-relative keys under .dirs). Empty if no lock yet.
if [[ -f "$LOCK" ]]; then
  mapfile -t baselined < <(jq -r '.dirs | keys[]' "$LOCK" 2>/dev/null || true)
else
  baselined=()
fi

is_baselined() {
  local d="$1"
  for b in "${baselined[@]:-}"; do
    [[ "$b" == "$d" ]] && return 0
  done
  return 1
}

filled=0
skipped=0

# All non-root AGENTS.md dirs, repo-root-relative, excluding vendored trees.
while IFS= read -r -d '' file; do
  dir="$(dirname "${file#./}")"
  [[ "$dir" == "." ]] && continue   # skip the repo-root AGENTS.md

  if is_baselined "$dir"; then
    skipped=$((skipped + 1))
    continue
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "would backfill: $dir"
  else
    echo "backfilling: $dir"
    "$WRITER" write "$dir"
  fi
  filled=$((filled + 1))
done < <(find . -name AGENTS.md \
           -not -path './node_modules/*' \
           -not -path './.git/*' \
           -print0 | sort -z)

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "dry run: $filled to backfill, $skipped already baselined"
else
  echo "done: $filled backfilled, $skipped already baselined"
fi
