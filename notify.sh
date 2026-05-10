#!/usr/bin/env bash
# =============================================================================
# Claude Code · Alert Hook
# Fires on every Notification event — plays sound + shows system notification
# =============================================================================
set -euo pipefail

# ── Read JSON from stdin ─────────────────────────────────────────────────────
INPUT=$(cat)

# Parse with python3 (always available where Claude Code runs)
read_json() {
  python3 -c "
import json, sys
try:
    d = json.loads('''$INPUT''')
    print(d.get('$1', '$2'))
except:
    print('$2')
" 2>/dev/null || echo "$2"
}

TITLE=$(python3 -c "
import json, sys
try:
    d = json.loads(sys.stdin.read())
    print(d.get('title', 'Claude Code'))
except:
    print('Claude Code')
" <<< "$INPUT")

MESSAGE=$(python3 -c "
import json, sys
try:
    d = json.loads(sys.stdin.read())
    print(d.get('message', 'Needs your attention'))
except:
    print('Needs your attention')
" <<< "$INPUT")

# ── Detect OS and notify ─────────────────────────────────────────────────────

# macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
  # System notification
  osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" sound name \"Ping\"" 2>/dev/null || true
  # Also use terminal-notifier if installed (richer notifications)
  if command -v terminal-notifier &>/dev/null; then
    terminal-notifier -title "$TITLE" -message "$MESSAGE" -sound "Ping" -group "claude-code" 2>/dev/null || true
  fi
fi

# Linux (requires libnotify / notify-send)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  if command -v notify-send &>/dev/null; then
    notify-send --urgency=critical --icon=dialog-question "$TITLE" "$MESSAGE" 2>/dev/null || true
  fi
  # Fallback: zenity dialog for critical input-needed events
  if echo "$MESSAGE" | grep -qiE "yes|no|confirm|permission|allow|approve"; then
    if command -v zenity &>/dev/null; then
      zenity --notification --text="$TITLE: $MESSAGE" 2>/dev/null || true
    fi
  fi
fi

# WSL (Windows Subsystem for Linux)
if grep -qi microsoft /proc/version 2>/dev/null; then
  powershell.exe -Command "
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > \$null
    \$template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
    \$textNodes = \$template.GetElementsByTagName('text')
    \$textNodes.Item(0).AppendChild(\$template.CreateTextNode('$TITLE')) > \$null
    \$textNodes.Item(1).AppendChild(\$template.CreateTextNode('$MESSAGE')) > \$null
    \$toast = [Windows.UI.Notifications.ToastNotification]::new(\$template)
    \$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Claude Code')
    \$notifier.Show(\$toast)
  " 2>/dev/null || true
fi

# ── Terminal bell (universal fallback) ───────────────────────────────────────
printf '\a'

# ── Print to stderr so it shows in Claude Code's output ──────────────────────
echo "🔔 $TITLE — $MESSAGE" >&2

exit 0
