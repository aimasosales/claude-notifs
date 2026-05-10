# claude-code-plugins

Two quality-of-life plugins for [Claude Code](https://docs.anthropic.com/en/docs/claude-code):

| Plugin | What it does |
|--------|-------------|
| 🔔 **Alert Hooks** | System notifications + sound when Claude needs your attention, is stalled, or about to run commands |
| ✨ **BetterPrompt** | A new "toggle" for Claude Code — type `/betterprompt` to have Claude ask you clarifying questions, then craft a precise, optimised version of your prompt before any work begins |

---

## ⚡ Quickstart — Paste this into Claude Code

> Open Claude Code in your terminal, then paste the entire block below and press Enter.

```
Please install the claude-code-plugins from this repo. Here's what to do:

1. Clone or ensure you're in the claude-code-plugins repo directory
2. Run: bash install.sh
3. After install, run: bash test.sh to verify everything works
4. If any tests fail, diagnose and fix them before reporting done
5. Show me the test results

Make sure:
- All three hooks (notify.sh, stall-alert.sh, permission-alert.sh) are installed and executable in ~/.claude/hooks/
- The betterprompt command is installed in ~/.claude/commands/betterprompt.md
- The hooks are registered in ~/.claude/settings.json
- At least one test notification fires successfully
- You restart or remind me to restart Claude Code after install

Report what was installed, what platform-specific setup was done, and confirm with the test output.
```

That's it. Claude Code will handle the rest.

---

## What gets installed

### 🔔 Alert Hooks (3 hooks)

**`notify.sh`** — Fires on every `Notification` event.  
Sends a desktop notification + sound when Claude needs your attention.

**`stall-alert.sh`** — Fires on every `Stop` event.  
Alerts you when Claude finishes or pauses — so you know when to look back at the terminal.

**`permission-alert.sh`** — Fires on `PreToolUse` for high-attention tools (Bash, file writes, web fetches).  
Pings you in the background when Claude is about to run something significant.

**Supported platforms:**
- macOS → `osascript` (built-in) + `terminal-notifier` (optional)
- Linux → `notify-send` (install: `sudo apt install libnotify-bin`)
- WSL → Windows toast notifications via PowerShell
- All → terminal bell (`\a`) as universal fallback

---

### ✨ BetterPrompt — `/betterprompt`

A global Claude Code slash command that works like a "prompt mode toggle" — similar to Shift+Tab cycling through Plan Mode and Auto-Accept Edits, but for your prompt itself.

**How to use:**

```bash
# In Claude Code, type:
/betterprompt build me a REST API for user auth

# Or with no args — it'll ask you:
/betterprompt
```

**What it does:**

1. **CLARIFY** — Asks you up to 4 targeted questions (goal, constraints, scope, ambiguities)
2. **CRAFT** — Builds an optimised prompt with a specific expert role/avatar, precise task definition, constraints, and success criteria
3. **DELIVER** — Gives you a copy-paste-ready prompt, then offers to execute it immediately

**Example flow:**

```
You:   /betterprompt make a dashboard

Claude: 🔍 Before I craft your optimised prompt:
        1. What data should the dashboard show?
        2. React or another framework?
        3. Real data source or mock data?
        4. New project or adding to existing?

You:   sales metrics, React, mock data, new project

Claude: 📋 Your Optimised Prompt (copy and paste this):
        ┌─────────────────────────────────────────────────┐
        │ You are a senior frontend engineer specialising  │
        │ in React data visualisation...                  │
        │                                                  │
        │ Build a sales metrics dashboard with:           │
        │ - Revenue, conversion rate, and MoM growth KPIs │
        │ ...                                             │
        └─────────────────────────────────────────────────┘

        Want me to adjust anything, or shall I execute this?
```

> **Note on Shift+Tab:** Claude Code's built-in toggle cycle (Auto-Accept Edits → Plan Mode) is hardcoded in the binary and can't be extended by plugins. `/betterprompt` is the equivalent experience as a slash command — invoke it any time before a big task.

---

## Manual install

If you prefer to install manually:

```bash
git clone https://github.com/YOUR_USERNAME/claude-code-plugins.git
cd claude-code-plugins
bash install.sh
bash test.sh
```

Then restart Claude Code.

---

## File structure

```
claude-code-plugins/
├── README.md               ← you are here
├── install.sh              ← main installer
├── uninstall.sh            ← clean removal
├── test.sh                 ← verify installation
├── merge-settings.py       ← safely merges hooks into settings.json
├── hooks/
│   ├── notify.sh           ← Notification hook
│   ├── stall-alert.sh      ← Stop hook
│   └── permission-alert.sh ← PreToolUse hook
└── commands/
    └── betterprompt.md     ← /betterprompt slash command
```

Hooks are installed to `~/.claude/hooks/`  
Commands are installed to `~/.claude/commands/`  
Settings are updated in `~/.claude/settings.json`

---

## Uninstall

```bash
bash uninstall.sh
```

Removes all hooks, the command file, and cleans hook entries from `settings.json`. Your other settings are untouched.

---

## Troubleshooting

**No notifications on macOS?**  
Check System Settings → Notifications → Terminal (or iTerm2/Warp) and enable alerts.

**No notifications on Linux?**  
```bash
sudo apt install libnotify-bin   # Ubuntu/Debian
sudo dnf install libnotify       # Fedora
```

**Hooks not firing after install?**  
Restart Claude Code — hooks are loaded at startup.

**`/betterprompt` not found?**  
Check that `~/.claude/commands/betterprompt.md` exists. If not, re-run `install.sh`.

**Want to edit the BetterPrompt behaviour?**  
Edit `~/.claude/commands/betterprompt.md` directly — it's plain markdown/text.

---

## How hooks work (for the curious)

Claude Code hooks are shell scripts registered in `~/.claude/settings.json`. They fire at lifecycle events:

| Event | When |
|-------|------|
| `Notification` | Claude sends a notification (needs attention, waiting, etc.) |
| `Stop` | Claude finishes responding or pauses |
| `PreToolUse` | Just before Claude uses any tool (Bash, file read/write, etc.) |
| `PostToolUse` | After a tool completes |

The hook receives a JSON payload via stdin describing the event. Exit code 0 = proceed, exit code 2 with JSON body = block the action (used for custom approval flows).

Slash commands (`/commandname`) are markdown files in `~/.claude/commands/`. The file content becomes the system instruction for that invocation. `$ARGUMENTS` is replaced with whatever the user typed after the command name.
