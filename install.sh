#!/usr/bin/env bash

# Claude Code Statusline Installer
# https://github.com/nomadec/claude-statusline

set -e

REPO_URL="https://raw.githubusercontent.com/nomadec/claude-statusline/main"
CLAUDE_DIR="$HOME/.claude"
SCRIPT_PATH="$CLAUDE_DIR/statusline.sh"
SETTINGS_PATH="$CLAUDE_DIR/settings.json"

echo "Installing Claude Code Statusline..."

# Create .claude directory if it doesn't exist
mkdir -p "$CLAUDE_DIR"

# Download the statusline script
echo "Downloading statusline.sh..."
curl -fsSL "$REPO_URL/statusline.sh" -o "$SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"

# Check for jq dependency
if ! command -v jq &> /dev/null; then
    echo ""
    echo "Warning: 'jq' is not installed. The statusline requires jq for JSON parsing."
    echo "Install it with:"
    echo "  macOS:  brew install jq"
    echo "  Ubuntu: sudo apt install jq"
    echo "  Fedora: sudo dnf install jq"
fi

# Check for npx dependency
if ! command -v npx &> /dev/null; then
    echo ""
    echo "Warning: 'npx' is not installed. Cost tracking requires Node.js/npm."
    echo "Install Node.js from: https://nodejs.org/"
fi

# Update settings.json
echo "Configuring settings.json..."

if [ -f "$SETTINGS_PATH" ]; then
    # Backup existing settings
    cp "$SETTINGS_PATH" "$SETTINGS_PATH.backup"

    # Check if statusLine already exists
    if grep -q '"statusLine"' "$SETTINGS_PATH"; then
        echo "Note: statusLine already configured in settings.json"
        echo "Backup saved to: $SETTINGS_PATH.backup"
        echo ""
        echo "To use claude-statusline, update your settings.json:"
        echo '  "statusLine": {'
        echo '    "type": "command",'
        echo '    "command": "~/.claude/statusline.sh",'
        echo '    "padding": 0'
        echo '  }'
    else
        # Add statusLine to existing settings using jq if available
        if command -v jq &> /dev/null; then
            jq '. + {"statusLine": {"type": "command", "command": "~/.claude/statusline.sh", "padding": 0}}' "$SETTINGS_PATH.backup" > "$SETTINGS_PATH"
            echo "Updated settings.json with statusLine configuration"
        else
            echo "Note: Could not auto-update settings.json (jq not installed)"
            echo "Add this to your $SETTINGS_PATH:"
            echo '  "statusLine": {'
            echo '    "type": "command",'
            echo '    "command": "~/.claude/statusline.sh",'
            echo '    "padding": 0'
            echo '  }'
        fi
    fi
else
    # Create new settings.json
    cat > "$SETTINGS_PATH" << 'EOF'
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh",
    "padding": 0
  }
}
EOF
    echo "Created settings.json with statusLine configuration"
fi

echo ""
echo "Installation complete!"
echo ""
echo "Restart Claude Code to see the statusline:"
echo "  ~/path on branch! [Model | \$X.XX | CTX: XX%] (today: \$X.XX | \$X.XX block (Xh Xm left))"
echo ""
echo "Features:"
echo "  - Session cost (matches /cost)"
echo "  - Context % (matches /context)"
echo "  - Git branch + status"
echo "  - Daily/block totals"
echo ""
echo "Color coding for context:"
echo "  Green:  < 65%"
echo "  Yellow: 65-75%"
echo "  Red:    > 75%"
