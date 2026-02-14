import SwiftUI

struct CompactLeadingView: View {
    @ObservedObject var sessionManager: SessionManager

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.9))

            if sessionManager.totalCount > 0 {
                Text("\(sessionManager.activeCount)/\(sessionManager.totalCount)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
        }
        .padding(.horizontal, 4)
    }
}
