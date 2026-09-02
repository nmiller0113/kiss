#!/usr/bin/env sh
# SessionStart hook for the K.I.S.S. plugin.
#
# Prints the shipped scope summary (skills/kiss/REMINDER.md) so it is in the
# model's context at every fresh-context boundary. A skill loads only when the
# model reads its description and judges it applies, so an installed skill can
# sit unread for a whole session while the model does the things it forbids.
# This hook removes that dependency on judgement.
#
# Claude Code adds a SessionStart hook's plain stdout to the context.
#
# Fails closed and silent: an unset CLAUDE_PLUGIN_ROOT, a missing file or an
# empty file all produce no output and exit 0. A boundary hook must never turn
# a session start into an error, and printing nothing is better than a false
# claim that the rule is in force.
set -u

root="${CLAUDE_PLUGIN_ROOT:-}"
[ -n "$root" ] || exit 0
reminder="$root/skills/kiss/REMINDER.md"
[ -s "$reminder" ] || exit 0

# Read BEFORE printing the header. `-s` stats the file and does not prove it is
# readable, so printing the header first can announce a rule and then emit nothing,
# which is the false claim this script says it prefers silence over.
text=$(cat "$reminder" 2>/dev/null) || exit 0
[ -n "$text" ] || exit 0

printf '=== scope constraint, from the installed kiss plugin ===\n\n%s\n' "$text"
exit 0
