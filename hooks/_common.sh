#!/bin/bash
# ClaudeNotch - Hook 共享辅助函数
# Claude Code hooks 通过 stdin 传入 JSON 数据

MONITOR_DIR="$HOME/.claude/notch-monitor/sessions"
mkdir -p "$MONITOR_DIR"

# 从 JSON 字符串中提取字段（优先 jq，fallback python3）
json_get() {
  local json="$1"
  local field="$2"
  if command -v jq &>/dev/null; then
    echo "$json" | jq -r ".$field // \"\""
  else
    echo "$json" | /usr/bin/python3 -c "import sys,json; print(json.load(sys.stdin).get('$field',''))" 2>/dev/null
  fi
}

# 提取 project name（从 cwd 取最后一个目录名）
get_project_name() {
  local cwd="$1"
  basename "$cwd"
}

# 从 ITERM_SESSION_ID 提取终端标识（如 "W0 Tab5"）
get_terminal_tab() {
  local iterm_id="${ITERM_SESSION_ID:-}"
  if [ -n "$iterm_id" ]; then
    # 格式: w0t5p0:UUID → 提取 w0t5
    local short=$(echo "$iterm_id" | sed 's/:.*//' | sed 's/p[0-9]*//')
    # w0t5 → W0 Tab5
    echo "$short" | sed 's/w\([0-9]*\)t\([0-9]*\)/W\1 Tab\2/'
  fi
}

# 获取 iTerm 当前 Tab 标题（通过 AppleScript，有缓存机制）
get_terminal_title() {
  local session_id="$1"
  local cache_file="$MONITOR_DIR/.title_cache_${session_id}"

  # 如果缓存存在且未超过 5 分钟，直接用缓存
  if [ -f "$cache_file" ]; then
    local age=$(( $(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || echo 0) ))
    if [ "$age" -lt 300 ]; then
      cat "$cache_file"
      return
    fi
  fi

  # 尝试通过 AppleScript 获取标题
  local title=""
  if [ -n "${ITERM_SESSION_ID:-}" ]; then
    title=$(osascript -e '
      tell application "iTerm2"
        try
          set currentTab to current tab of current window
          return name of currentTab
        end try
      end tell
    ' 2>/dev/null)
  fi

  # 缓存结果
  if [ -n "$title" ]; then
    printf '%s' "$title" > "$cache_file"
    echo "$title"
  fi
}

# 原子写入状态文件（先写 .tmp 再 mv，防竞争）
write_status() {
  local session_id="$1"
  local status="$2"
  local hook_event="$3"
  local tool_name="${4:-}"
  local tool_input_summary="${5:-}"
  local cwd="${6:-}"
  local message="${7:-}"

  local project_name=""
  if [ -n "$cwd" ]; then
    project_name=$(get_project_name "$cwd")
  fi

  local terminal_tab
  terminal_tab=$(get_terminal_tab)

  # 只在 SessionStart 时获取终端标题（避免频繁调用 osascript）
  local terminal_title=""
  if [ "$hook_event" = "SessionStart" ]; then
    terminal_title=$(get_terminal_title "$session_id")
  else
    # 读已有文件中的 terminal_title
    local existing="$MONITOR_DIR/${session_id}.json"
    if [ -f "$existing" ]; then
      terminal_title=$(json_get "$(cat "$existing")" "terminal_title")
    fi
  fi

  local timestamp
  timestamp=$(date +%s)

  local tmp_file="$MONITOR_DIR/${session_id}.json.tmp"
  local target_file="$MONITOR_DIR/${session_id}.json"

  # 转义 JSON 字符串中的特殊字符
  tool_input_summary=$(printf '%s' "$tool_input_summary" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ' | head -c 500)
  message=$(printf '%s' "$message" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ' | head -c 500)
  terminal_title=$(printf '%s' "$terminal_title" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ' | head -c 60)

  local iterm_session_id="${ITERM_SESSION_ID:-}"

  cat > "$tmp_file" << ENDJSON
{
  "session_id": "${session_id}",
  "status": "${status}",
  "tool_name": "${tool_name}",
  "tool_input_summary": "${tool_input_summary}",
  "cwd": "${cwd}",
  "project_name": "${project_name}",
  "terminal_tab": "${terminal_tab}",
  "terminal_title": "${terminal_title}",
  "timestamp": ${timestamp},
  "hook_event": "${hook_event}",
  "message": "${message}",
  "iterm_session_id": "${iterm_session_id}"
}
ENDJSON

  mv "$tmp_file" "$target_file"
}
