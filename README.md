# Claude Code Statusline

Real-time stats display for [Claude Code](https://claude.com/code) CLI showing session cost, context usage, and git status.

## Screenshot

```
~/projects/myapp on main! [Opus 4.5 | $3.43 | CTX: 32%] (today: $5.44 | $5.44 block (3h 19m left))
```

## Features

- **Session cost** - Matches `/cost` output (Claude Code's actual calculation)
- **Context %** - Current context window usage (matches `/context`)
- **Git integration** - Branch, dirty status (`!`), untracked (`?`), ahead/behind (`↑↓`)
- **Daily summary** - Today's total and 5-hour block with time remaining
- **Color-coded context** - Green (<65%), Yellow (65-75%), Red (>75%)

## Installation

### One-liner (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/nomadec/claude-statusline/main/install.sh | bash
```

### Manual

1. Download the script:
```bash
curl -o ~/.claude/statusline.sh https://raw.githubusercontent.com/nomadec/claude-statusline/main/statusline.sh
chmod +x ~/.claude/statusline.sh
```

2. Add to `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh",
    "padding": 0
  }
}
```

3. Restart Claude Code.

## Dependencies

- **jq** - JSON parsing
  - macOS: `brew install jq`
  - Ubuntu: `sudo apt install jq`
- **Node.js/npx** - For cost tracking via [ccusage](https://github.com/ryoppippi/ccusage)
  - Install from [nodejs.org](https://nodejs.org/)

## Output Format

```
~/path on branch! [Model | $X.XX | CTX: XX%] (today: $X.XX | $X.XX block (Xh Xm left))
│        │     │   │       │       │          │            └─ 5-hour block cost + time remaining
│        │     │   │       │       │          └─ Today's total cost
│        │     │   │       │       └─ Context window usage (color-coded)
│        │     │   │       └─ Session cost
│        │     │   └─ Model name (Opus 4.5, Sonnet, Haiku)
│        │     └─ Git status: ! (changes), ? (untracked), ↑↓ (ahead/behind)
│        └─ Git branch
└─ Working directory
```

## Customization

Edit `~/.claude/statusline.sh` to customize:

### Change color thresholds

```bash
# Line ~29-35
if [ "$ctx_percent" -lt 65 ]; then    # Change 65 to your preferred threshold
    ctx_color="32"  # green
elif [ "$ctx_percent" -lt 75 ]; then  # Change 75 to your preferred threshold
    ctx_color="33"  # yellow
else
    ctx_color="31"  # red
fi
```

### Remove components

Comment out or delete sections you don't need (git info, cost, daily summary, etc.)

## How It Works

1. Claude Code pipes JSON session data to the statusline command via stdin
2. The script extracts context usage from the `current_usage` object (accurate context %)
3. Cost data comes from [ccusage](https://github.com/ryoppippi/ccusage) with `--cost-source cc` (uses Claude Code's actual cost, not token-based estimates)
4. Git status is fetched via standard git commands

## Troubleshooting

**Statusline not showing?**
- Restart Claude Code after installation
- Check `~/.claude/settings.json` has the statusLine configuration

**Cost not showing?**
- Ensure Node.js/npx is installed: `npx --version`
- ccusage downloads automatically on first run

**Context % not showing?**
- Ensure jq is installed: `jq --version`

**Wrong cost displayed?**
- Make sure the script uses `--cost-source cc` (Claude Code's calculation)
- Third-party calculations don't account for multi-model sessions or web searches

## Credits

- [ccusage](https://github.com/ryoppippi/ccusage) - Cost tracking data
- [claude-code-statusline](https://github.com/levz0r/claude-code-statusline) - Inspiration for shell script approach

## License

MIT
