#!/usr/bin/env bash
# =============================================================================
# Claude Code · Stall Alert Hook
# Fires on Stop events — tells you Claude has paused and needs you back
# =============================================================================
set -euo pipefail

INPUT=$(cat)

# Parse stop reason
STOP_REASON=$(python3 -c "
import json, sys
try:
    d = json.loads(sys.stdin.read())
    print(d.get('stop_reason', 'unknown'))
except:
    print('unknown')
" <<< "$INPUT")

# Only alert on non-natural stops (i.e. Claude is waiting, not just done)
# stop_reason: 'end_turn' = done naturally, 'tool_use' = waiting on tool result
# We alert on anything that means Claude needs you

TITLE="Claude Code — Paused"
MESSAGE="Claude stopped and may need your input"

case "$STOP_REASON" in
  "end_turn")
    TITLE="Claude Code — Done ✅"
    MESSAGE="Task complete. Review output and give your next instruction."
    ;;
  "max_tokens")
    TITLE="Claude Code — Hit token limit ⚠️"
    MESSAGE="Response cut off. You may need to continue or adjust the task."
    ;;
  "stop_sequence")
    TITLE="Claude Code — Waiting 🔔"
    MESSAGE="Claude is paused and waiting for your input."
    ;;
  *)
    TITLE="Claude Code — Needs Attention 🔔"
    MESSAGE="Claude stopped ($STOP_REASON). Check the terminal."
    ;;
esac

# ── macOS ─────────────────────────────────────────────────────────────────────
if [[ "$OSTYPE" == "darwin"* ]]; then
  osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" sound name \"Glass\"" 2>/dev/null || true
  # Bring Terminal/iTerm to front if not focused
  osascript -e '
    tell application "System Events"
      set frontApp to name of first application process whose frontmost is true
      if frontApp is not "Terminal" and frontApp is not "iTerm2" and frontApp is not "Warp" then
        display notification "'"$MESSAGE"'" with title "'"$TITLE"'" sound name "Glass"
      end if
    end tell
  ' 2>/dev/null || true
fi

# ── Linux ─────────────────────────────────────────────────────────────────────
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  if command -v notify-send &>/dev/null; then
    notify-send --urgency=normal --icon=dialog-information "$TITLE" "$MESSAGE" 2>/dev/null || true
  fi
fi

# ── Terminal bell ─────────────────────────────────────────────────────────────
printf '\a'
echo "🛑 $TITLE — $MESSAGE" >&2

exit 0
