import SwiftUI

struct MascotView: View {
    let status: SessionStatus
    @State private var bouncing = false
    @State private var eyeBlinking = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.8), Color.orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 1) {
                HStack(spacing: 5) {
                    eyeShape
                    eyeShape
                }
                mouthShape
            }
            .offset(y: 1)
        }
        .scaleEffect(bouncing ? 1.1 : 1.0)
        .animation(
            status.isActive
                ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
                : .easeInOut(duration: 0.3),
            value: bouncing
        )
        .onChange(of: status) { _, newStatus in
            bouncing = newStatus.isActive
        }
        .onAppear {
            bouncing = status.isActive
            startBlinkTimer()
        }
    }

    @ViewBuilder
    private var eyeShape: some View {
        Ellipse()
            .fill(.white)
            .frame(width: 5, height: eyeBlinking ? 1 : 5)
    }

    @ViewBuilder
    private var mouthShape: some View {
        switch status {
        case .error:
            // 皱眉
            Canvas { context, size in
                var path = Path()
                path.move(to: CGPoint(x: 0, y: size.height))
                path.addQuadCurve(
                    to: CGPoint(x: size.width, y: size.height),
                    control: CGPoint(x: size.width / 2, y: 0)
                )
                context.stroke(path, with: .color(.white), lineWidth: 1.5)
            }
            .frame(width: 10, height: 4)
        case .completed, .ended:
            // 微笑（小）
            Canvas { context, size in
                var path = Path()
                path.move(to: CGPoint(x: 0, y: 0))
                path.addQuadCurve(
                    to: CGPoint(x: size.width, y: 0),
                    control: CGPoint(x: size.width / 2, y: size.height)
                )
                context.stroke(path, with: .color(.white), lineWidth: 1.5)
            }
            .frame(width: 8, height: 3)
        default:
            // 开心大笑
            Canvas { context, size in
                var path = Path()
                path.move(to: CGPoint(x: 0, y: 0))
                path.addQuadCurve(
                    to: CGPoint(x: size.width, y: 0),
                    control: CGPoint(x: size.width / 2, y: size.height)
                )
                context.stroke(path, with: .color(.white), lineWidth: 1.5)
            }
            .frame(width: 10, height: 5)
        }
    }

    private func startBlinkTimer() {
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.15)) {
                    eyeBlinking = true
                }
                try? await Task.sleep(for: .milliseconds(150))
                withAnimation(.easeInOut(duration: 0.15)) {
                    eyeBlinking = false
                }
            }
        }
    }
}
