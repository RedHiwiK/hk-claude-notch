import SwiftUI

struct CompactTrailingView: View {
    @ObservedObject var sessionManager: SessionManager
    @State private var isPulsing = false

    var body: some View {
        Circle()
            .fill(sessionManager.overallStatus.color)
            .frame(width: 8, height: 8)
            .scaleEffect(isPulsing ? 1.3 : 1.0)
            .animation(
                sessionManager.overallStatus.isActive
                    ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                    : .default,
                value: isPulsing
            )
            .onChange(of: sessionManager.overallStatus) { _, newStatus in
                isPulsing = newStatus.isActive
            }
            .onAppear {
                isPulsing = sessionManager.overallStatus.isActive
            }
            .padding(.trailing, 4)
    }
}
