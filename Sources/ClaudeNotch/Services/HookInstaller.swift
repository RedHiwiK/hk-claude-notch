import Foundation

/// 在 app 启动时自动安装/更新 Claude Code hooks
enum HookInstaller {
    private static let hookDir = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".claude/notch-monitor/hooks")
    private static let sessionDir = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".claude/notch-monitor/sessions")
    private static let settingsFile = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".claude/settings.json")

    private static let hookScripts = [
        "_common.sh",
        "session-start.sh",
        "pre-tool-use.sh",
        "post-tool-use.sh",
        "stop.sh",
        "session-end.sh",
        "notification.sh",
    ]

    /// 检查并安装/更新 hooks（幂等操作）
    static func installIfNeeded() {
        let fm = FileManager.default

        // 创建目录
        try? fm.createDirectory(at: hookDir, withIntermediateDirectories: true)
        try? fm.createDirectory(at: sessionDir, withIntermediateDirectories: true)

        // 查找 hook 源文件目录
        guard let srcDir = findHookSourceDir() else { return }

        // 复制 hook 脚本
        for script in hookScripts {
            let src = srcDir.appendingPathComponent(script)
            let dst = hookDir.appendingPathComponent(script)
            guard fm.fileExists(atPath: src.path) else { continue }

            // 比较内容，不同才覆盖
            if let srcData = try? Data(contentsOf: src),
               let dstData = try? Data(contentsOf: dst),
               srcData == dstData {
                continue
            }

            try? fm.removeItem(at: dst)
            try? fm.copyItem(at: src, to: dst)

            // chmod +x
            try? fm.setAttributes(
                [.posixPermissions: 0o755],
                ofItemAtPath: dst.path
            )
        }

        // 合并 hooks 配置到 settings.json
        mergeHooksConfig()
    }

    private static func findHookSourceDir() -> URL? {
        // 优先从 .app bundle 的 Resources/hooks/ 查找
        if let resourcePath = Bundle.main.resourceURL {
            let bundleHooks = resourcePath.appendingPathComponent("hooks")
            if FileManager.default.fileExists(atPath: bundleHooks.appendingPathComponent("_common.sh").path) {
                return bundleHooks
            }
        }

        // 开发模式：从可执行文件相对路径推导
        let execURL = URL(fileURLWithPath: CommandLine.arguments[0])
        let devHooks = execURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("hooks")
        if FileManager.default.fileExists(atPath: devHooks.appendingPathComponent("_common.sh").path) {
            return devHooks
        }

        return nil
    }

    private static func mergeHooksConfig() {
        let hooksConfig: [String: Any] = [
            "hooks": [
                "SessionStart": [
                    ["hooks": [["type": "command", "command": "~/.claude/notch-monitor/hooks/session-start.sh"]]]
                ],
                "PreToolUse": [
                    ["hooks": [["type": "command", "command": "~/.claude/notch-monitor/hooks/pre-tool-use.sh"]]]
                ],
                "PostToolUse": [
                    ["hooks": [["type": "command", "command": "~/.claude/notch-monitor/hooks/post-tool-use.sh"]]]
                ],
                "Stop": [
                    ["hooks": [["type": "command", "command": "~/.claude/notch-monitor/hooks/stop.sh"]]]
                ],
                "Notification": [
                    ["hooks": [["type": "command", "command": "~/.claude/notch-monitor/hooks/notification.sh"]]]
                ],
                "SessionEnd": [
                    ["hooks": [["type": "command", "command": "~/.claude/notch-monitor/hooks/session-end.sh"]]]
                ],
            ]
        ]

        let fm = FileManager.default
        var existing: [String: Any] = [:]

        if fm.fileExists(atPath: settingsFile.path),
           let data = try? Data(contentsOf: settingsFile),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            existing = json
        }

        // 检查是否已经配置了 hooks
        if let existingHooks = existing["hooks"] as? [String: Any],
           existingHooks.keys.contains("SessionStart"),
           existingHooks.keys.contains("PreToolUse") {
            // 已配置，跳过
            return
        }

        // 合并
        if let newHooks = hooksConfig["hooks"] as? [String: Any] {
            var mergedHooks = (existing["hooks"] as? [String: Any]) ?? [:]
            for (key, value) in newHooks {
                mergedHooks[key] = value
            }
            existing["hooks"] = mergedHooks
        }

        // 写入
        if let data = try? JSONSerialization.data(withJSONObject: existing, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: settingsFile, options: .atomic)
        }
    }
}
