import SwiftUI

struct SessionRowView: View {
    let session: SessionState
    @State private var isAnimating = false
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // 主行
            HStack(spacing: 8) {
                // 状态图标
                ZStack {
                    Circle()
                        .fill(session.status.color.opacity(0.2))
                        .frame(width: 24, height: 24)

                    Image(systemName: session.status.sfSymbol)
                        .font(.system(size: 11))
                        .foregroundStyle(session.status.color)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(
                            session.status == .toolRunning
                                ? .linear(duration: 2).repeatForever(autoreverses: false)
                                : .default,
                            value: isAnimating
                        )
                }

                // 项目名 + 工具信息
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.displayLabel)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        if let toolName = session.toolName, !toolName.isEmpty {
                            Text(toolName)
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundStyle(session.status.color)
                        }
                        if let summary = session.toolInputSummary, !summary.isEmpty {
                            Text(summary)
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.5))
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                // 展开指示器
                if hasExpandableContent {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.3))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.spring(response: 0.3), value: isExpanded)
                }

                if session.status == .pendingApproval {
                    // 审批按钮
                    Button {
                        if let itermId = session.itermSessionId, !itermId.isEmpty {
                            ApprovalService.approve(itermSessionId: itermId)
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                            Text("Approve")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.yellow)
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    // 状态标签
                    Text(session.status.displayName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(session.status.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(session.status.color.opacity(0.15))
                        )
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .onTapGesture {
                guard hasExpandableContent else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }

            // 展开详情区域
            if isExpanded, hasExpandableContent {
                expandedDetailView
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(session.status == .pendingApproval
                    ? Color.yellow.opacity(0.1)
                    : Color.white.opacity(0.05))
        )
        .overlay(
            session.status == .pendingApproval
                ? RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.yellow.opacity(0.3), lineWidth: 1)
                : nil
        )
        .onAppear {
            isAnimating = session.status == .toolRunning
        }
    }

    // MARK: - 展开详情

    private var hasExpandableContent: Bool {
        if let summary = session.toolInputSummary, summary.count > 40 {
            return true
        }
        if let msg = session.message, !msg.isEmpty, msg.count > 40 {
            return true
        }
        return false
    }

    @ViewBuilder
    private var expandedDetailView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .overlay(Color.white.opacity(0.1))

            if let summary = session.toolInputSummary, !summary.isEmpty {
                Text(summary)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(8)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let msg = session.message, !msg.isEmpty,
               msg != session.toolInputSummary {
                Text(msg)
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // 操作按钮（仅 pendingApproval 状态）
            if session.status == .pendingApproval {
                HStack(spacing: 8) {
                    Spacer()

                    Button {
                        if let itermId = session.itermSessionId, !itermId.isEmpty {
                            ApprovalService.approve(itermSessionId: itermId)
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                            Text("Approve")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.yellow))
                    }
                    .buttonStyle(.plain)

                    if let itermId = session.itermSessionId, !itermId.isEmpty {
                        Button {
                            ApprovalService.activateITermSession(itermSessionId: itermId)
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.up.forward.app")
                                    .font(.system(size: 9, weight: .bold))
                                Text("iTerm")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.white.opacity(0.15)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.03))
        )
    }
}
