import SwiftUI

/// Reusable empty state view for consistent empty states across the app
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(ColorTokens.textSecondary)
                .padding(.bottom, Spacing.sm)
            
            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(Typography.headlineSmall)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.xl)
            
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(Typography.titleSmall)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.vertical, Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                                .fill(ColorTokens.primary)
                        )
                }
                .padding(.top, Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xl)
    }
}

#Preview {
    EmptyStateView(
        icon: "tray.fill",
        title: "No Expenses Yet",
        subtitle: "Start tracking your expenses by adding your first transaction",
        actionTitle: "Add Expense",
        action: { print("Add tapped") }
    )
}
