#!/usr/bin/env bash
# Claude Code PreToolUse(Bash) hook — the scope-init staleness gate.
#
# When Claude is about to run `git push` via Bash, run the staleness check first.
# Push (not commit) is the gate point on purpose: commits are work-in-progress and
# may still be reworked, but a push means "this is probably done, headed for a PR" —
# the right moment to insist a documented directory's AGENTS.md is still current.
#
# If a documented directory drifted from its AGENTS.md, exit 2 — Claude Code treats
# that as a blocking error and feeds stderr back to the model instead of running the
# command. Wired up in .claude/settings.json under PreToolUse -> matcher "Bash".
#
# Note: this only gates pushes Claude makes through Bash. Pushes made directly in a
# terminal or IDE are not intercepted (that would need a git pre-push hook). Run
# `scripts/scope-staleness.sh check` manually to audit on demand.
set -euo pipefail

input="$(cat)"
cmd="$(printf '%s' "$input" | python3 -c \
  'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' \
  2>/dev/null || true)"

# Only gate real pushes; ignore everything else and explicit bypasses.
case "$cmd" in
  *"git push"*) ;;
  *) exit 0 ;;
esac
case "$cmd" in
  *"--no-verify"*) exit 0 ;;
esac

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ -x "$ROOT/scripts/scope-staleness.sh" ] || exit 0

# (1) Blocking: documented dirs that drifted from their AGENTS.md. Exit 2 stops the push
# and feeds stderr back to the model. Checks the worktree state that's about to be pushed.
if ! out="$("$ROOT/scripts/scope-staleness.sh" check 2>&1)"; then
  {
    echo "scope-init staleness gate blocked this push:"
    echo "$out"
    echo "Re-run /scope-init for the listed dir(s), or push with --no-verify to bypass."
  } >&2
  exit 2
fi

# (2) Non-blocking: undocumented dirs that look worth scoping. A missing doc for a dir
# nobody asked to document shouldn't hard-block a push, so instead of exit 2 we inject a
# note as PreToolUse additionalContext (same mechanism the graphify hook uses) — the push
# proceeds and the model sees the suggestion. `ignore <dir>` silences a false positive.
cand="$("$ROOT/scripts/scope-staleness.sh" discover 2>/dev/null || true)"
if [ -n "$cand" ]; then
  list="$(printf '%s\n' "$cand" | while IFS=$'\t' read -r d cnt ext; do
    [ -n "$d" ] && printf -- '- %s/ (%s %s files, no AGENTS.md)\n' "$d" "$cnt" "$ext"
  done)"
  msg="scope-init discovery: directories that look worth documenting but have no AGENTS.md:
${list}
Consider running /scope-init <dir> for each, or 'scripts/scope-staleness.sh ignore <dir>' to stop flagging it."
  msg="$msg" python3 -c 'import json,os; print(json.dumps({"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":os.environ["msg"]}}))'
fi
exit 0
