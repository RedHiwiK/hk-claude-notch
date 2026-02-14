import Foundation
import SwiftUI

enum SessionStatus: String, Codable, CaseIterable, Sendable {
    case started = "started"
    case thinking = "thinking"
    case toolRunning = "tool_running"
    case toolCompleted = "tool_completed"
    case completed = "completed"
    case ended = "ended"
    case error = "error"
    case pendingApproval = "pending_approval"

    var displayName: String {
        switch self {
        case .started: "Starting"
        case .thinking: "Thinking"
        case .toolRunning: "Running"
        case .toolCompleted: "Done"
        case .completed: "Idle"
        case .ended: "Ended"
        case .error: "Error"
        case .pendingApproval: "Approval"
        }
    }

    var sfSymbol: String {
        switch self {
        case .started: "bolt.circle.fill"
        case .thinking: "ellipsis.bubble.fill"
        case .toolRunning: "gearshape.fill"
        case .toolCompleted: "checkmark.seal.fill"
        case .completed: "pause.circle.fill"
        case .ended: "xmark.circle.fill"
        case .error: "exclamationmark.octagon.fill"
        case .pendingApproval: "bell.badge.fill"
        }
    }

    var color: Color {
        switch self {
        case .started: .blue
        case .thinking: .purple
        case .toolRunning: .orange
        case .toolCompleted: .green
        case .completed: .gray
        case .ended: .secondary
        case .error: .red
        case .pendingApproval: .yellow
        }
    }

    var isActive: Bool {
        switch self {
        case .started, .thinking, .toolRunning, .pendingApproval: true
        default: false
        }
    }

    /// 排序权重：数值越大越靠前显示
    var sortPriority: Int {
        switch self {
        case .pendingApproval: 100
        case .toolRunning: 90
        case .thinking: 80
        case .started: 70
        case .toolCompleted: 40
        case .error: 30
        case .completed: 20
        case .ended: 10
        }
    }
}

struct SessionState: Codable, Identifiable, Sendable {
    let sessionId: String
    var status: SessionStatus
    var toolName: String?
    var toolInputSummary: String?
    var cwd: String?
    var projectName: String?
    var terminalTab: String?
    var terminalTitle: String?
    var timestamp: TimeInterval
    var hookEvent: String?
    var message: String?
    var itermSessionId: String?

    var id: String { sessionId }

    /// 用于显示的标识名：项目名-自定义名 · Tab → 项目名 · Tab → 项目名
    var displayLabel: String {
        let name = projectName ?? "Unknown"
        let hasTitle = terminalTitle != nil && !terminalTitle!.isEmpty
        let hasTab = terminalTab != nil && !terminalTab!.isEmpty

        // 组合项目名和自定义标题
        let prefix = hasTitle ? "\(name)-\(terminalTitle!)" : name

        if hasTab {
            return "\(prefix) · \(terminalTab!)"
        }
        return prefix
    }

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case status
        case toolName = "tool_name"
        case toolInputSummary = "tool_input_summary"
        case cwd
        case projectName = "project_name"
        case terminalTab = "terminal_tab"
        case terminalTitle = "terminal_title"
        case timestamp
        case hookEvent = "hook_event"
        case message
        case itermSessionId = "iterm_session_id"
    }

    var secondsSinceUpdate: TimeInterval {
        Date().timeIntervalSince1970 - timestamp
    }
}
