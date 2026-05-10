#!/usr/bin/env bash
# =============================================================================
# claude-code-plugins · test.sh
# Verifies all hooks and commands are installed and working correctly
# =============================================================================
set -euo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

PASS=0; FAIL=0

pass() { echo -e "${GREEN}  ✅ PASS${RESET} — $*"; ((PASS++)); }
fail() { echo -e "${RED}  ❌ FAIL${RESET} — $*"; ((FAIL++)); }
info() { echo -e "${CYAN}  ℹ  $*${RESET}"; }
section() { echo -e "\n${BOLD}$*${RESET}"; }

CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
COMMANDS_DIR="$CLAUDE_DIR/commands"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

echo ""
echo -e "${BOLD}${CYAN}claude-code-plugins · Test Suite${RESET}"
echo "══════════════════════════════════"

# ── 1. Claude Code ────────────────────────────────────────────────────────────
section "1. Claude Code"
if command -v claude &>/dev/null; then
  pass "Claude Code installed ($(which claude))"
else
  fail "Claude Code not found — install with: npm install -g @anthropic-ai/claude-code"
fi

# ── 2. Hooks exist ────────────────────────────────────────────────────────────
section "2. Hook files"
for hook in notify.sh stall-alert.sh permission-alert.sh; do
  hook_path="$HOOKS_DIR/$hook"
  if [[ -f "$hook_path" ]]; then
    if [[ -x "$hook_path" ]]; then
      pass "$hook (exists and executable)"
    else
      fail "$hook exists but not executable — run: chmod +x $hook_path"
    fi
  else
    fail "$hook not found at $hook_path — run install.sh"
  fi
done

# ── 3. BetterPrompt command ───────────────────────────────────────────────────
section "3. BetterPrompt command"
CMD_PATH="$COMMANDS_DIR/betterprompt.md"
if [[ -f "$CMD_PATH" ]]; then
  pass "betterprompt.md found at $CMD_PATH"
  # Check it has the key sections
  for keyword in "PHASE 1" "PHASE 2" "PHASE 3" "ARGUMENTS"; do
    if grep -q "$keyword" "$CMD_PATH"; then
      pass "  Contains: $keyword"
    else
      fail "  Missing: $keyword (command file may be corrupted)"
    fi
  done
else
  fail "betterprompt.md not found — run install.sh"
fi

# ── 4. Settings.json ──────────────────────────────────────────────────────────
section "4. Settings.json hooks"
if [[ -f "$SETTINGS_FILE" ]]; then
  for hook_event in "Notification" "Stop" "PreToolUse"; do
    if python3 -c "
import json, sys
with open('$SETTINGS_FILE') as f:
    s = json.load(f)
hooks = s.get('hooks', {})
event_hooks = hooks.get('$hook_event', [])
commands = [h['command'] for e in event_hooks for h in e.get('hooks', [])]
has_plugin = any('$HOOKS_DIR' in c for c in commands)
sys.exit(0 if has_plugin else 1)
" 2>/dev/null; then
      pass "$hook_event hook registered in settings.json"
    else
      fail "$hook_event hook not found in settings.json — run install.sh"
    fi
  done
else
  fail "settings.json not found at $SETTINGS_FILE — run install.sh"
fi

# ── 5. Live hook test ─────────────────────────────────────────────────────────
section "5. Live notification test"
TEST_JSON='{"title":"Test Alert","message":"Hook is working correctly ✅"}'

if echo "$TEST_JSON" | bash "$HOOKS_DIR/notify.sh" 2>/dev/null; then
  pass "notify.sh executed successfully"
  info "You should have seen/heard a notification"
else
  fail "notify.sh failed to execute"
fi

if echo '{"stop_reason":"end_turn"}' | bash "$HOOKS_DIR/stall-alert.sh" 2>/dev/null; then
  pass "stall-alert.sh executed successfully"
else
  fail "stall-alert.sh failed to execute"
fi

TEST_TOOL_JSON='{"tool_name":"Bash","tool_input":{"command":"echo test"}}'
if echo "$TEST_TOOL_JSON" | bash "$HOOKS_DIR/permission-alert.sh" 2>/dev/null; then
  pass "permission-alert.sh executed successfully"
else
  fail "permission-alert.sh failed to execute"
fi

# ── 6. Platform notifications ─────────────────────────────────────────────────
section "6. Platform notification support"
if [[ "$OSTYPE" == "darwin"* ]]; then
  if osascript -e 'return true' &>/dev/null; then
    pass "macOS osascript available"
  else
    fail "osascript not working"
  fi
  if command -v terminal-notifier &>/dev/null; then
    pass "terminal-notifier installed (enhanced notifications)"
  else
    info "terminal-notifier not installed (optional): brew install terminal-notifier"
  fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  if command -v notify-send &>/dev/null; then
    pass "notify-send available"
  else
    fail "notify-send not found — sudo apt install libnotify-bin"
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════"
TOTAL=$((PASS + FAIL))
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All $TOTAL tests passed ✅${RESET}"
  echo ""
  echo -e "  ${BOLD}You're good to go! Try these in Claude Code:${RESET}"
  echo ""
  echo -e "  ${CYAN}/betterprompt build me a todo app${RESET}"
  echo -e "  ${CYAN}/betterprompt${RESET} (with no args — it'll ask you)"
  echo ""
  echo -e "  Alerts will fire automatically when Claude needs your attention."
else
  echo -e "${RED}${BOLD}$FAIL/$TOTAL tests failed ❌${RESET}"
  echo ""
  echo -e "  Run ${BOLD}bash install.sh${RESET} to fix missing components"
fi
echo ""
