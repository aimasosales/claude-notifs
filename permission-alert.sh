#!/usr/bin/env bash
# =============================================================================
# Claude Code · Permission Alert Hook (PreToolUse)
# Fires BEFORE every tool use — alerts when Claude is about to do something
# that needs your eyes on it (bash commands, writes, deletes, network calls)
# =============================================================================
set -euo pipefail

INPUT=$(cat)

TOOL_NAME=$(python3 -c "
import json, sys
try:
    d = json.loads(sys.stdin.read())
    print(d.get('tool_name', 'unknown'))
except:
    print('unknown')
" <<< "$INPUT")

TOOL_INPUT=$(python3 -c "
import json, sys
try:
    d = json.loads(sys.stdin.read())
    inp = d.get('tool_input', {})
    # Get the most relevant field
    for key in ['command', 'path', 'file_path', 'url', 'query']:
        if key in inp:
            val = str(inp[key])
            print(val[:120] + ('...' if len(val) > 120 else ''))
            sys.exit(0)
    print(str(inp)[:120])
except:
    print('(unknown input)')
" <<< "$INPUT")

# ── Only alert on high-attention tools ───────────────────────────────────────
HIGH_ATTENTION_TOOLS=(
  "Bash"
  "computer"
  "str_replace_editor"
  "create_file"
  "delete_file"
  "web_fetch"
  "web_search"
)

SHOULD_ALERT=false
for tool in "${HIGH_ATTENTION_TOOLS[@]}"; do
  if [[ "$TOOL_NAME" == "$tool" ]]; then
    SHOULD_ALERT=true
    break
  fi
done

if [[ "$SHOULD_ALERT" == "false" ]]; then
  exit 0
fi

TITLE="Claude Code — Running: $TOOL_NAME"
MESSAGE="$TOOL_INPUT"

# ── macOS ─────────────────────────────────────────────────────────────────────
if [[ "$OSTYPE" == "darwin"* ]]; then
  # Only notify if window is not focused (don't spam focused users)
  IS_FOCUSED=$(osascript -e '
    tell application "System Events"
      set frontApp to name of first application process whose frontmost is true
      if frontApp is "Terminal" or frontApp is "iTerm2" or frontApp is "Warp" then
        return "focused"
      else
        return "background"
      end if
    end tell
  ' 2>/dev/null || echo "background")
  
  if [[ "$IS_FOCUSED" == "background" ]]; then
    osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\"" 2>/dev/null || true
  fi
fi

# ── Linux ─────────────────────────────────────────────────────────────────────
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  if command -v notify-send &>/dev/null; then
    notify-send --urgency=low "$TITLE" "$MESSAGE" 2>/dev/null || true
  fi
fi

# Always allow the tool to run (exit 0 = proceed)
exit 0
