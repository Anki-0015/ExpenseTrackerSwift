import SwiftUI

/// Reusable stat card for displaying key metrics
struct StatCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    var icon: String? = nil
    var iconColor: Color = ColorTokens.primary
    var trend: TrendIndicator? = nil
    
    enum TrendIndicator {
        case up(String)
        case down(String)
        case neutral(String)
        
        var color: Color {
            switch self {
            case .up: return ColorTokens.success
            case .down: return ColorTokens.error
            case .neutral: return ColorTokens.textSecondary
            }
        }
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }
        
        var text: String {
            switch self {
            case .up(let value), .down(let value), .neutral(let value):
                return value
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: Spacing.iconMedium))
                        .foregroundStyle(iconColor)
                }
                
                Text(title)
                    .font(Typography.captionLarge)
                    .foregroundStyle(ColorTokens.textSecondary)
                
                Spacer()
                
                if let trend {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: trend.icon)
                            .font(Typography.captionSmall)
                        Text(trend.text)
                            .font(Typography.captionMedium)
                    }
                    .foregroundStyle(trend.color)
                }
            }
            
            Text(value)
                .font(Typography.headlineMedium)
                .foregroundStyle(ColorTokens.textPrimary)
            
            if let subtitle {
                Text(subtitle)
                    .font(Typography.captionMedium)
                    .foregroundStyle(ColorTokens.textTertiary)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                .fill(ColorTokens.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                .strokeBorder(ColorTokens.borderLight, lineWidth: Spacing.borderThin)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        StatCard(
            title: "Total Spent",
            value: "$1,234.56",
            subtitle: "This month",
            icon: "dollarsign.circle.fill",
            iconColor: ColorTokens.error,
            trend: .up("+12%")
        )
        
        StatCard(
            title: "Savings",
            value: "$5,432.10",
            subtitle: "All goals",
            icon: "piggybank.fill",
            iconColor: ColorTokens.success,
            trend: .down("-5%")
        )
        
        StatCard(
            title: "Average Daily",
            value: "$41.15",
            icon: "chart.bar.fill"
        )
    }
    .padding()
}
