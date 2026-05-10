#!/usr/bin/env python3
"""
merge-settings.py — Safely merges claude-code-plugins hook configuration
into ~/.claude/settings.json without overwriting existing settings.
"""
import json
import sys
import os
from pathlib import Path
from copy import deepcopy

HOOKS_DIR = str(Path.home() / ".claude" / "hooks")

PLUGIN_HOOKS = {
    "Notification": [
        {
            "matcher": "",
            "hooks": [
                {
                    "type": "command",
                    "command": f"{HOOKS_DIR}/notify.sh"
                }
            ]
        }
    ],
    "Stop": [
        {
            "matcher": "",
            "hooks": [
                {
                    "type": "command",
                    "command": f"{HOOKS_DIR}/stall-alert.sh"
                }
            ]
        }
    ],
    "PreToolUse": [
        {
            "matcher": "",
            "hooks": [
                {
                    "type": "command",
                    "command": f"{HOOKS_DIR}/permission-alert.sh"
                }
            ]
        }
    ]
}

def merge_hooks(existing_hooks: dict, new_hooks: dict) -> dict:
    """Merge new hooks into existing, avoiding duplicates by command path."""
    merged = deepcopy(existing_hooks)
    
    for event_type, new_entries in new_hooks.items():
        if event_type not in merged:
            merged[event_type] = []
        
        for new_entry in new_entries:
            # Check if any hook with this command already exists
            new_commands = {h["command"] for h in new_entry.get("hooks", [])}
            
            already_exists = False
            for existing_entry in merged[event_type]:
                existing_commands = {h["command"] for h in existing_entry.get("hooks", [])}
                if new_commands & existing_commands:  # intersection
                    already_exists = True
                    break
            
            if not already_exists:
                merged[event_type].append(new_entry)
    
    return merged


def main():
    settings_path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.home() / ".claude" / "settings.json"
    
    # Load existing settings
    if settings_path.exists():
        with open(settings_path) as f:
            try:
                settings = json.load(f)
            except json.JSONDecodeError:
                print(f"⚠️  Could not parse {settings_path} — creating backup and starting fresh")
                backup = settings_path.with_suffix(".json.bak")
                settings_path.rename(backup)
                settings = {}
    else:
        settings = {}
        settings_path.parent.mkdir(parents=True, exist_ok=True)
    
    # Merge hooks
    existing_hooks = settings.get("hooks", {})
    merged_hooks = merge_hooks(existing_hooks, PLUGIN_HOOKS)
    settings["hooks"] = merged_hooks
    
    # Write back
    with open(settings_path, "w") as f:
        json.dump(settings, f, indent=2)
    
    print(f"✅ Settings updated: {settings_path}")
    print(f"   Hooks registered: {', '.join(PLUGIN_HOOKS.keys())}")


if __name__ == "__main__":
    main()
