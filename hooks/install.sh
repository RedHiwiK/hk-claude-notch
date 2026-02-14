#!/bin/bash
# ClaudeNotch Hook 安装脚本
# 将 hook 脚本安装到 ~/.claude/notch-monitor/hooks/
# 并将 hooks 配置合并到 ~/.claude/settings.json

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK_DIR="$HOME/.claude/notch-monitor/hooks"
SESSION_DIR="$HOME/.claude/notch-monitor/sessions"
SETTINGS="$HOME/.claude/settings.json"

echo "🔧 Installing ClaudeNotch hooks..."

# 创建目录
mkdir -p "$HOOK_DIR" "$SESSION_DIR"

# 复制 hook 脚本
for script in _common.sh session-start.sh pre-tool-use.sh post-tool-use.sh stop.sh session-end.sh; do
  cp "$SCRIPT_DIR/$script" "$HOOK_DIR/$script"
  chmod +x "$HOOK_DIR/$script"
  echo "  ✓ Installed $script"
done

# 生成 hooks 配置
HOOKS_CONFIG=$(cat << 'JSONEOF'
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/notch-monitor/hooks/session-start.sh"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/notch-monitor/hooks/pre-tool-use.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/notch-monitor/hooks/post-tool-use.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/notch-monitor/hooks/stop.sh"
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/notch-monitor/hooks/session-end.sh"
          }
        ]
      }
    ]
  }
}
JSONEOF
)

# 合并配置到 settings.json
if [ -f "$SETTINGS" ]; then
  if command -v jq &>/dev/null; then
    # 使用 jq 深度合并
    echo "$HOOKS_CONFIG" | jq -s '.[0] * .[1]' "$SETTINGS" - > "${SETTINGS}.tmp"
    mv "${SETTINGS}.tmp" "$SETTINGS"
    echo "  ✓ Merged hooks config into $SETTINGS"
  else
    echo "  ⚠️  jq not found. Please manually add hooks config to $SETTINGS"
    echo "  Config to add:"
    echo "$HOOKS_CONFIG"
  fi
else
  echo "$HOOKS_CONFIG" > "$SETTINGS"
  echo "  ✓ Created $SETTINGS with hooks config"
fi

echo ""
echo "✅ ClaudeNotch hooks installed successfully!"
echo "   Hook scripts: $HOOK_DIR"
echo "   Session data: $SESSION_DIR"
echo "   Settings: $SETTINGS"
echo ""
echo "   Restart your Claude Code sessions to activate hooks."
