import SwiftUI

struct SessionRowView: View {
    let session: SessionState
    @State private var isAnimating = false

    var body: some View {
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
}
