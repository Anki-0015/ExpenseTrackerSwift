import SwiftUI

/// Consistent spacing system for the app
/// Use these tokens instead of hardcoded values for consistent layout
struct Spacing {
    
    // MARK: - Spacing Scale
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
    
    // MARK: - Common Padding Values
    static let cardPadding: CGFloat = 16
    static let screenPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
    static let itemSpacing: CGFloat = 12
    
    // MARK: - Border Radius
    static let radiusSmall: CGFloat = 8
    static let radiusMedium: CGFloat = 12
    static let radiusLarge: CGFloat = 16
    static let radiusXLarge: CGFloat = 24
    
    // MARK: - Border Width
    static let borderThin: CGFloat = 0.5
    static let borderMedium: CGFloat = 1
    static let borderThick: CGFloat = 2
    
    // MARK: - Icon Sizes
    static let iconSmall: CGFloat = 16
    static let iconMedium: CGFloat = 24
    static let iconLarge: CGFloat = 32
    static let iconXLarge: CGFloat = 48
}

// MARK: - View Extension for Convenient Usage
extension View {
    func cardStyle() -> some View {
        self
            .padding(Spacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: Spacing.radiusLarge, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.radiusLarge, style: .continuous)
                    .strokeBorder(ColorTokens.borderLight, lineWidth: Spacing.borderThin)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}
