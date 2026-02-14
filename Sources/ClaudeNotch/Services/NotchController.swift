import SwiftUI
import DynamicNotchKit
import Combine

@MainActor
final class NotchController {
    private var dynamicNotch: DynamicNotch<
        NotchContentView,
        CompactLeadingView,
        CompactTrailingView
    >?

    let sessionManager: SessionManager
    private var cancellables = Set<AnyCancellable>()
    /// 防止 session 变化 sink 把展开状态压回 compact
    private var isUserExpanded = false
    /// 动画进行中时锁住 hover 逻辑
    private var isAnimating = false
    /// 收起延迟任务（防抖）
    private var collapseTask: Task<Void, Never>?

    /// 全局鼠标移动监听器
    private nonisolated(unsafe) var mouseMonitor: Any?
    private nonisolated(unsafe) var localMouseMonitor: Any?

    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }

    func setup() {
        let notch = DynamicNotch(
            hoverBehavior: .all,
            style: .auto
        ) {
            NotchContentView(sessionManager: self.sessionManager)
        } compactLeading: {
            CompactLeadingView(sessionManager: self.sessionManager)
        } compactTrailing: {
            CompactTrailingView(sessionManager: self.sessionManager)
        }
        dynamicNotch = notch

        // 有会话时显示 compact，无会话时隐藏
        sessionManager.$sessions
            .receive(on: RunLoop.main)
            .sink { [weak self] sessions in
                guard let self else { return }
                Task {
                    if sessions.isEmpty {
                        self.isUserExpanded = false
                        await self.hide()
                    } else if !self.isUserExpanded {
                        await self.showCompact()
                    }
                }
            }
            .store(in: &cancellables)

        // 有 pendingApproval 时自动展开
        sessionManager.$sessions
            .receive(on: RunLoop.main)
            .map { $0.contains { $0.status == .pendingApproval } }
            .removeDuplicates()
            .sink { [weak self] hasPending in
                guard let self else { return }
                if hasPending {
                    Task {
                        self.isUserExpanded = true
                        await self.animatedExpand()
                    }
                } else if self.isUserExpanded {
                    Task {
                        self.isUserExpanded = false
                        await self.animatedCompact()
                    }
                }
            }
            .store(in: &cancellables)

        // 全局鼠标移动监听：检测 notch 区域 hover
        setupMouseHoverMonitor()
    }

    // MARK: - Mouse Hover Detection

    private func setupMouseHoverMonitor() {
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            Task { @MainActor in
                self?.handleMouseMoved()
            }
        }
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            Task { @MainActor in
                self?.handleMouseMoved()
            }
            return event
        }
    }

    private func handleMouseMoved() {
        guard dynamicNotch != nil, !sessionManager.sessions.isEmpty, !isAnimating else { return }

        let mouseLocation = NSEvent.mouseLocation
        let isInZone = isMouseInNotchArea(mouseLocation)

        if isInZone && !isUserExpanded {
            // 鼠标进入 → 取消任何待定的收起，立即展开
            collapseTask?.cancel()
            collapseTask = nil
            isUserExpanded = true
            Task {
                await animatedExpand()
            }
        } else if !isInZone && isUserExpanded && !sessionManager.hasPendingApproval {
            // 鼠标离开 → 延迟收起（防抖，给用户回来的机会）
            if collapseTask == nil {
                collapseTask = Task {
                    try? await Task.sleep(for: .milliseconds(400))
                    guard !Task.isCancelled else { return }
                    // 再次确认鼠标确实不在区域内
                    let currentMouse = NSEvent.mouseLocation
                    guard !self.isMouseInNotchArea(currentMouse) else { return }
                    self.isUserExpanded = false
                    await self.animatedCompact()
                    self.collapseTask = nil
                }
            }
        } else if isInZone && isUserExpanded {
            // 鼠标回来了 → 取消收起
            collapseTask?.cancel()
            collapseTask = nil
        }
    }

    /// 检测鼠标是否在 notch 交互区域
    private func isMouseInNotchArea(_ mouseLocation: NSPoint) -> Bool {
        // 展开状态：用窗口实际 frame + 边距判断
        if isUserExpanded, let window = dynamicNotch?.windowController?.window {
            let frame = window.frame
            // 窗口 frame 加上 20pt 边距，防止边缘抖动
            let expandedFrame = frame.insetBy(dx: -20, dy: -20)
            return expandedFrame.contains(mouseLocation)
        }

        // compact 状态：检查屏幕顶部 notch 区域
        guard let screen = NSScreen.main else { return false }
        let screenFrame = screen.frame
        let notchWidth: CGFloat = 300
        let notchHeight: CGFloat = 40

        let notchRect = NSRect(
            x: screenFrame.midX - notchWidth / 2,
            y: screenFrame.maxY - notchHeight,
            width: notchWidth,
            height: notchHeight
        )

        return notchRect.contains(mouseLocation)
    }

    // MARK: - Animated State Transitions

    private func animatedExpand() async {
        guard !isAnimating, let notch = dynamicNotch else { return }
        isAnimating = true
        await notch.expand()
        // expand 内部动画约 0.4-0.65s，额外等一点确保稳定
        try? await Task.sleep(for: .milliseconds(100))
        isAnimating = false
    }

    private func animatedCompact() async {
        guard !isAnimating, let notch = dynamicNotch else { return }
        isAnimating = true
        await notch.compact()
        try? await Task.sleep(for: .milliseconds(100))
        isAnimating = false
    }

    // MARK: - State Control

    func showCompact() async {
        guard let notch = dynamicNotch else { return }
        await notch.compact()
    }

    func showExpanded() async {
        guard let notch = dynamicNotch else { return }
        await notch.expand()
    }

    func hide() async {
        guard let notch = dynamicNotch else { return }
        await notch.hide()
    }

    deinit {
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localMouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
