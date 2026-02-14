import Foundation
import SwiftUI

@MainActor
final class SessionManager: ObservableObject {
    @Published var sessions: [SessionState] = []

    private let fileWatcher = FileWatcherService()
    private var cleanupTimer: Timer?
    private var debounceTask: Task<Void, Never>?

    var activeSessions: [SessionState] {
        sessions.filter { $0.status.isActive }
    }

    var activeCount: Int { activeSessions.count }
    var totalCount: Int { sessions.count }

    var hasPendingApproval: Bool {
        sessions.contains { $0.status == .pendingApproval }
    }

    var pendingApprovals: [SessionState] {
        sessions.filter { $0.status == .pendingApproval }
    }

    var overallStatus: SessionStatus {
        if sessions.isEmpty { return .ended }
        if sessions.contains(where: { $0.status == .pendingApproval }) { return .pendingApproval }
        if sessions.contains(where: { $0.status == .error }) { return .error }
        if sessions.contains(where: { $0.status == .toolRunning }) { return .toolRunning }
        if sessions.contains(where: { $0.status == .thinking }) { return .thinking }
        if sessions.contains(where: { $0.status == .started }) { return .started }
        if sessions.contains(where: { $0.status == .toolCompleted }) { return .toolCompleted }
        return .completed
    }

    func start() {
        fileWatcher.onDirectoryChanged = { [weak self] in
            self?.debouncedReload()
        }
        fileWatcher.startWatching()
        reloadSessions()

        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.cleanupStaleSessions()
            }
        }
    }

    func stop() {
        fileWatcher.stopWatching()
        cleanupTimer?.invalidate()
        debounceTask?.cancel()
    }

    private func debouncedReload() {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            reloadSessions()
        }
    }

    private func reloadSessions() {
        let newSessions = fileWatcher.scanSessions()
        withAnimation(.easeInOut(duration: 0.3)) {
            sessions = newSessions
        }
    }

    private func cleanupStaleSessions() {
        let staleThreshold: TimeInterval = 1800
        let staleIds = sessions
            .filter { $0.secondsSinceUpdate > staleThreshold }
            .map(\.sessionId)

        if !staleIds.isEmpty {
            // 删除过期文件
            let home = FileManager.default.homeDirectoryForCurrentUser
            let dir = home.appendingPathComponent(".claude/notch-monitor/sessions")
            for id in staleIds {
                try? FileManager.default.removeItem(at: dir.appendingPathComponent("\(id).json"))
            }
            reloadSessions()
        }
    }
}
