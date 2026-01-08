import SwiftUI

/// Customizable progress bar component
struct ProgressBar: View {
    let value: Double // 0.0 to 1.0
    var height: CGFloat = 8
    var color: Color = ColorTokens.primary
    var backgroundColor: Color = ColorTokens.surfaceSecondary
    var showPercentage: Bool = false
    
    private var clampedValue: Double {
        min(max(value, 0.0), 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(backgroundColor)
                        .frame(height: height)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(color)
                        .frame(width: geometry.size.width * clampedValue, height: height)
                        .animation(.smooth(duration: 0.3), value: clampedValue)
                }
            }
            .frame(height: height)
            
            if showPercentage {
                Text("\(Int(clampedValue * 100))%")
                    .font(Typography.captionMedium)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
        }
    }
}

#Preview {
    VStack(spacing: Spacing.xl) {
        ProgressBar(value: 0.3)
        ProgressBar(value: 0.6, color: ColorTokens.success, showPercentage: true)
        ProgressBar(value: 0.9, color: ColorTokens.warning, showPercentage: true)
        ProgressBar(value: 1.1, color: ColorTokens.error, showPercentage: true)
    }
    .padding()
}
