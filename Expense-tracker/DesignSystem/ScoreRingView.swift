import SwiftUI

struct ScoreRingView: View {
    let score: Int
    var lineWidth: CGFloat = 10

    private var clamped: Double { Double(max(0, min(100, score))) / 100.0 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    .tint,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.smooth(duration: 0.7), value: clamped)

            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                Text("Health")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Monthly financial health")
        .accessibilityValue("\(score) out of 100")
    }
}
