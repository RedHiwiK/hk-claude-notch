import SwiftUI

struct NotchContentView: View {
    @ObservedObject var sessionManager: SessionManager
    @State private var isShowingAll = false

    private let maxVisibleSessions = 5

    var body: some View {
        VStack(spacing: 8) {
            // 标题栏
            HStack {
                MascotView(status: sessionManager.overallStatus)
                    .frame(width: 28, height: 28)

                Text("Claude Sessions")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Text("\(sessionManager.activeCount) active")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            Divider()
                .background(Color.white.opacity(0.2))

            // 会话列表
            SessionListView(
                sessions: sessionManager.sessions,
                maxVisible: maxVisibleSessions,
                isShowingAll: $isShowingAll
            )
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .frame(width: 320)
    }
}
