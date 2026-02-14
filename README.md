<div align="center">

<img src="Resources/AppIcon.png" width="128" alt="ClaudeNotch Icon">

# ClaudeNotch

**Monitor your Claude Code sessions from the MacBook notch.**

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org/)
[![macOS 14+](https://img.shields.io/badge/macOS-14+-blue.svg)](https://developer.apple.com/macos/)
[![Release](https://img.shields.io/github/v/release/RedHiwiK/hk-claude-notch)](https://github.com/RedHiwiK/hk-claude-notch/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

[English](#english) · [中文](#中文)

</div>

---

## English

A native macOS menu bar app that displays real-time Claude Code CLI session status in the MacBook notch area (Dynamic Island style). Powered by [DynamicNotchKit](https://github.com/MrKai77/DynamicNotchKit).

### Features

| Feature | Description |
|---------|-------------|
| **Notch Status Display** | Compact mode shows active/total session count + pulsing status indicator |
| **Expandable Session List** | Hover to expand and see all sessions with project name, tool name, and status |
| **Click to Expand Details** | Click any session row to reveal full command text / file paths |
| **One-Click Approval** | Approve permission prompts directly from the notch — no need to switch windows |
| **Jump to iTerm** | Open the corresponding iTerm tab for multi-option approval scenarios |
| **Smart Sorting** | Sessions sorted by priority: pending approval > running > thinking > idle > ended |
| **5+ Session Support** | Collapsible list with "show more" for heavy multitaskers |
| **Cute Mascot** | Animated face that bounces when active, blinks randomly, and changes expression by status |
| **Zero Config** | One install script sets up everything |

### How It Works

```
Claude Code Sessions (1..N)
    │  Hooks write JSON on each event
    ▼
~/.claude/notch-monitor/sessions/{session_id}.json
    │  FSEvents directory watching
    ▼
ClaudeNotch App → Notch UI
```

**Session statuses:** Started → Thinking → Tool Running → Tool Completed → Idle → Ended

### Install (DMG)

1. Download the latest `ClaudeNotch.dmg` from [Releases](https://github.com/RedHiwiK/hk-claude-notch/releases)
2. Open the DMG and drag **ClaudeNotch.app** to `/Applications`
3. Remove macOS quarantine (the app is not code-signed):
```bash
xattr -cr /Applications/ClaudeNotch.app
```
4. Open ClaudeNotch from Applications (hooks are installed automatically on first launch)
5. Restart your Claude Code sessions to activate hooks

### Build from Source

Requires Swift 6.0+ toolchain.

```bash
git clone https://github.com/RedHiwiK/hk-claude-notch.git
cd hk-claude-notch

# Build & install hooks
swift build
./hooks/install.sh

# Run
swift run ClaudeNotch
```

### Prerequisites

- macOS 14+ (Sonoma or later)
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed
- `jq` recommended (`brew install jq`), falls back to Python 3

### Menu Bar Controls

| Action | Description |
|--------|-------------|
| **Show Notch** (⌘S) | Expand the notch to show full session list |
| **Hide Notch** (⌘H) | Hide the notch display |
| **Quit** (⌘Q) | Exit ClaudeNotch |

### Status Colors

| Color | Status |
|-------|--------|
| 🔵 Blue | Session started |
| 🟣 Purple | Claude is thinking |
| 🟠 Orange | Tool is running |
| 🟢 Green | Tool completed |
| 🟡 Yellow | Pending approval |
| ⚪ Gray | Idle (waiting for input) |
| 🔴 Red | Error |

### Project Structure

```
claude-notch/
├── Package.swift                    # SPM config, depends on DynamicNotchKit
├── Sources/ClaudeNotch/
│   ├── App/                         # App entry + AppDelegate
│   ├── Models/                      # SessionState, SessionManager
│   ├── Views/                       # NotchContent, SessionList, Mascot, etc.
│   └── Services/                    # FileWatcher, NotchController, ApprovalService
├── hooks/                           # Claude Code hook scripts + installer
└── scripts/                         # Build & packaging scripts
```

### Hook Events

| Event | Trigger | Status Written |
|-------|---------|----------------|
| `SessionStart` | Claude Code session begins | `started` |
| `PreToolUse` | Before a tool executes | `tool_running` |
| `PostToolUse` | After a tool completes | `thinking` |
| `Notification` | Permission prompt received | `pending_approval` |
| `Stop` | Claude finishes responding | `completed` |
| `SessionEnd` | Session exits | File deleted |

---

## 中文

一款原生 macOS 菜单栏应用，利用 MacBook 刘海屏区域（Dynamic Island 风格）实时展示 Claude Code CLI 会话状态。基于 [DynamicNotchKit](https://github.com/MrKai77/DynamicNotchKit) 构建。

### 功能特性

| 功能 | 说明 |
|------|------|
| **刘海屏状态显示** | 紧凑模式显示活跃/总会话数 + 脉冲状态指示灯 |
| **可展开会话列表** | 鼠标悬停展开，查看所有会话的项目名、工具名和状态 |
| **点击展开详情** | 点击任意会话行，查看完整命令文本 / 文件路径 |
| **一键审批** | 直接在刘海屏批准权限请求，无需切换窗口 |
| **跳转 iTerm** | 多选项审批场景下，一键打开对应的 iTerm tab |
| **智能排序** | 会话按优先级排序：待审批 > 运行中 > 思考中 > 空闲 > 已结束 |
| **5+ 会话支持** | 可折叠列表，支持 "显示更多"，适合多任务重度用户 |
| **可爱吉祥物** | 活跃时上下弹跳、随机眨眼、根据状态变换表情的动画小脸 |
| **零配置** | 一个安装脚本搞定一切 |

### 工作原理

```
Claude Code 会话 (1..N)
    │  每个事件通过 Hook 写入 JSON
    ▼
~/.claude/notch-monitor/sessions/{session_id}.json
    │  FSEvents 目录监听
    ▼
ClaudeNotch App → 刘海屏 UI
```

**会话状态流转：** 已启动 → 思考中 → 工具运行中 → 工具完成 → 空闲 → 已结束

### 安装（DMG）

1. 从 [Releases](https://github.com/RedHiwiK/hk-claude-notch/releases) 下载最新的 `ClaudeNotch.dmg`
2. 打开 DMG，将 **ClaudeNotch.app** 拖入 `/Applications`
3. 移除 macOS 隔离属性（应用未签名）：
```bash
xattr -cr /Applications/ClaudeNotch.app
```
4. 从启动台打开 ClaudeNotch（首次启动自动安装 hooks）
5. 重启你的 Claude Code 会话以激活 hooks

### 从源码构建

需要 Swift 6.0+ 工具链。

```bash
git clone https://github.com/RedHiwiK/hk-claude-notch.git
cd hk-claude-notch

# 编译 & 安装 hooks
swift build
./hooks/install.sh

# 运行
swift run ClaudeNotch
```

### 环境要求

- macOS 14+（Sonoma 或更高）
- 已安装 [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)
- 推荐安装 `jq`（`brew install jq`），未安装时回退到 Python 3

### 菜单栏操作

| 操作 | 说明 |
|------|------|
| **Show Notch** (⌘S) | 展开刘海屏显示完整会话列表 |
| **Hide Notch** (⌘H) | 隐藏刘海屏显示 |
| **Quit** (⌘Q) | 退出 ClaudeNotch |

### 状态颜色对照

| 颜色 | 状态 |
|------|------|
| 🔵 蓝色 | 会话已启动 |
| 🟣 紫色 | Claude 正在思考 |
| 🟠 橙色 | 工具运行中 |
| 🟢 绿色 | 工具执行完成 |
| 🟡 黄色 | 待审批 |
| ⚪ 灰色 | 空闲（等待输入） |
| 🔴 红色 | 出错 |

### Hook 事件说明

| 事件 | 触发时机 | 写入状态 |
|------|---------|---------|
| `SessionStart` | Claude Code 会话启动 | `started` |
| `PreToolUse` | 工具执行前 | `tool_running` |
| `PostToolUse` | 工具执行后 | `thinking` |
| `Notification` | 收到权限审批请求 | `pending_approval` |
| `Stop` | Claude 完成响应 | `completed` |
| `SessionEnd` | 会话退出 | 删除文件 |
