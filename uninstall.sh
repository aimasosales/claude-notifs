#!/usr/bin/env bash
# =============================================================================
# claude-code-plugins · uninstall.sh
# =============================================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RESET='\033[0m'
success() { echo -e "${GREEN}✅ $*${RESET}"; }
info()    { echo -e "${YELLOW}ℹ  $*${RESET}"; }

CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
COMMANDS_DIR="$CLAUDE_DIR/commands"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

echo -e "${RED}Uninstalling claude-code-plugins...${RESET}"

# Remove hooks
for f in notify.sh stall-alert.sh permission-alert.sh; do
  if [[ -f "$HOOKS_DIR/$f" ]]; then
    rm "$HOOKS_DIR/$f"
    success "Removed hook: $f"
  fi
done

# Remove command
if [[ -f "$COMMANDS_DIR/betterprompt.md" ]]; then
  rm "$COMMANDS_DIR/betterprompt.md"
  success "Removed command: betterprompt"
fi

# Clean hooks from settings.json
if [[ -f "$SETTINGS_FILE" ]]; then
  python3 - "$SETTINGS_FILE" "$HOOKS_DIR" << 'EOF'
import json, sys
from pathlib import Path

settings_path = Path(sys.argv[1])
hooks_dir = sys.argv[2]

with open(settings_path) as f:
    settings = json.load(f)

def clean_hooks(hooks_section, hooks_dir):
    cleaned = {}
    for event, entries in hooks_section.items():
        new_entries = []
        for entry in entries:
            new_hooks = [h for h in entry.get("hooks", [])
                        if hooks_dir not in h.get("command", "")]
            if new_hooks:
                entry["hooks"] = new_hooks
                new_entries.append(entry)
        if new_entries:
            cleaned[event] = new_entries
    return cleaned

if "hooks" in settings:
    settings["hooks"] = clean_hooks(settings["hooks"], hooks_dir)

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)

print("✅ Hooks removed from settings.json")
EOF
fi

echo ""
echo -e "${GREEN}Uninstall complete. Restart Claude Code to apply.${RESET}"
