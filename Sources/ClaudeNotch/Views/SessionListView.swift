import SwiftUI

struct SessionListView: View {
    let sessions: [SessionState]
    let maxVisible: Int
    @Binding var isShowingAll: Bool

    private var visibleSessions: [SessionState] {
        if isShowingAll || sessions.count <= maxVisible {
            return sessions
        }
        return Array(sessions.prefix(maxVisible))
    }

    var body: some View {
        VStack(spacing: 4) {
            if sessions.isEmpty {
                Text("No active sessions")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.vertical, 12)
            } else {
                ForEach(visibleSessions) { session in
                    SessionRowView(session: session)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                }

                if sessions.count > maxVisible {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isShowingAll.toggle()
                        }
                    } label: {
                        HStack {
                            Text(isShowingAll
                                ? "Show less"
                                : "+\(sessions.count - maxVisible) more sessions")
                                .font(.system(size: 11, weight: .medium))
                            Image(systemName: isShowingAll ? "chevron.up" : "chevron.down")
                                .font(.system(size: 9))
                        }
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
