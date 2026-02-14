import Foundation

/// 通过 AppleScript 向 iTerm session 发送按键来批准权限请求
enum ApprovalService {
    /// 向指定 iTerm session 发送 "y" + 回车以批准权限
    static func approve(itermSessionId: String) {
        // 从 ITERM_SESSION_ID 提取 tty（格式: w0t0p0:UUID）
        let sessionUUID: String
        if let colonIndex = itermSessionId.firstIndex(of: ":") {
            sessionUUID = String(itermSessionId[itermSessionId.index(after: colonIndex)...])
        } else {
            sessionUUID = itermSessionId
        }

        let script = """
        tell application "iTerm2"
            repeat with aWindow in windows
                repeat with aTab in tabs of aWindow
                    repeat with aSession in sessions of aTab
                        if unique ID of aSession is "\(sessionUUID)" then
                            tell aSession
                                write text "y"
                            end tell
                            return
                        end if
                    end repeat
                end repeat
            end repeat
        end tell
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
    }
}
