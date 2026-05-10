#!/usr/bin/env bash
# =============================================================================
# claude-code-plugins · install.sh
# Installs alert hooks and BetterPrompt command into your Claude Code setup
# =============================================================================
set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}ℹ  $*${RESET}"; }
success() { echo -e "${GREEN}✅ $*${RESET}"; }
warn()    { echo -e "${YELLOW}⚠️  $*${RESET}"; }
error()   { echo -e "${RED}❌ $*${RESET}"; }
header()  { echo -e "\n${BOLD}${BLUE}$*${RESET}"; }

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
COMMANDS_DIR="$CLAUDE_DIR/commands"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

header "═══════════════════════════════════════════════"
header "   claude-code-plugins · Installer"
header "═══════════════════════════════════════════════"
echo ""

# ── Pre-flight checks ─────────────────────────────────────────────────────────
header "🔍 Pre-flight checks"

# Check Claude Code is installed
if ! command -v claude &>/dev/null; then
  error "Claude Code not found. Install it first:"
  echo "   npm install -g @anthropic-ai/claude-code"
  exit 1
fi
success "Claude Code found: $(which claude)"

# Check Python 3
if ! command -v python3 &>/dev/null; then
  error "Python 3 is required for settings management"
  exit 1
fi
success "Python 3 found: $(python3 --version)"

# ── Create directories ────────────────────────────────────────────────────────
header "📁 Setting up directories"
mkdir -p "$HOOKS_DIR" "$COMMANDS_DIR"
success "Created $HOOKS_DIR"
success "Created $COMMANDS_DIR"

# ── Install hooks ─────────────────────────────────────────────────────────────
header "🪝 Installing hooks"

for hook_file in "$SCRIPT_DIR/hooks/"*.sh; do
  hook_name=$(basename "$hook_file")
  dest="$HOOKS_DIR/$hook_name"
  cp "$hook_file" "$dest"
  chmod +x "$dest"
  success "Installed hook: $hook_name"
done

# ── Install BetterPrompt command ──────────────────────────────────────────────
header "✨ Installing BetterPrompt command"

cp "$SCRIPT_DIR/commands/betterprompt.md" "$COMMANDS_DIR/betterprompt.md"
success "Installed global command: /betterprompt"

# ── Merge settings.json ───────────────────────────────────────────────────────
header "⚙️  Updating Claude Code settings"

# Backup existing settings
if [[ -f "$SETTINGS_FILE" ]]; then
  BACKUP="$SETTINGS_FILE.backup-$(date +%Y%m%d-%H%M%S)"
  cp "$SETTINGS_FILE" "$BACKUP"
  info "Backed up existing settings to: $BACKUP"
fi

python3 "$SCRIPT_DIR/merge-settings.py" "$SETTINGS_FILE"

# ── Platform-specific setup ───────────────────────────────────────────────────
header "🖥  Platform setup"

if [[ "$OSTYPE" == "darwin"* ]]; then
  success "macOS detected — notifications will use osascript (no extra setup needed)"
  
  # Check for terminal-notifier (optional enhancement)
  if command -v brew &>/dev/null && ! command -v terminal-notifier &>/dev/null; then
    info "Optional: install terminal-notifier for richer notifications:"
    echo "   brew install terminal-notifier"
  fi

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  if command -v notify-send &>/dev/null; then
    success "Linux detected — notify-send found, notifications ready"
  else
    warn "Linux detected — install libnotify for desktop notifications:"
    echo "   Ubuntu/Debian: sudo apt install libnotify-bin"
    echo "   Fedora:        sudo dnf install libnotify"
    echo "   Arch:          sudo pacman -S libnotify"
  fi

elif grep -qi microsoft /proc/version 2>/dev/null; then
  success "WSL detected — will use Windows toast notifications"

else
  warn "Unknown platform — terminal bell alerts only (no desktop notifications)"
fi

# ── Test notification ─────────────────────────────────────────────────────────
header "🧪 Testing notification"

TEST_JSON='{"title":"claude-code-plugins","message":"Installation successful! Alerts are working ✅"}'
echo "$TEST_JSON" | bash "$HOOKS_DIR/notify.sh" 2>/dev/null || true
success "Test notification sent"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
header "═══════════════════════════════════════════════"
echo -e "${GREEN}${BOLD}   Installation complete! 🎉${RESET}"
header "═══════════════════════════════════════════════"
echo ""
echo -e "  ${BOLD}What's installed:${RESET}"
echo ""
echo -e "  ${CYAN}🔔 Alert Hooks${RESET}"
echo -e "     • Notification hook  → system alert when Claude needs attention"
echo -e "     • Stop hook          → alert when Claude pauses/finishes"
echo -e "     • PreToolUse hook    → alert when Claude runs commands (background)"
echo ""
echo -e "  ${CYAN}✨ BetterPrompt Toggle${RESET}"
echo -e "     • Use ${BOLD}/betterprompt your rough idea here${RESET} in Claude Code"
echo -e "     • Claude will ask clarifying questions, then craft an optimised prompt"
echo -e "     • Works like Shift+Tab Plan Mode — but for your prompt, not the plan"
echo ""
echo -e "  ${CYAN}🔧 Settings updated:${RESET} $SETTINGS_FILE"
echo ""
echo -e "  ${YELLOW}Restart Claude Code for hooks to take effect.${RESET}"
echo ""
