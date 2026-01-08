import SwiftUI

/// Comprehensive color system for the Expense Tracker app
/// Provides semantic colors for consistent usage across the app
struct ColorTokens {
    
    // MARK: - Brand Colors
    static let primary = Color.accentColor
    static let primaryLight = Color.accentColor.opacity(0.1)
    static let primaryDark = Color.accentColor.opacity(0.8)
    
    // MARK: - Semantic Colors
    static let success = Color.green
    static let successLight = Color.green.opacity(0.1)
    static let successDark = Color.green.opacity(0.8)
    
    static let warning = Color.orange
    static let warningLight = Color.orange.opacity(0.1)
    static let warningDark = Color.orange.opacity(0.8)
    
    static let error = Color.red
    static let errorLight = Color.red.opacity(0.1)
    static let errorDark = Color.red.opacity(0.8)
    
    static let info = Color.blue
    static let infoLight = Color.blue.opacity(0.1)
    static let infoDark = Color.blue.opacity(0.8)
    
    // MARK: - Surface Colors
    static let surface = Color(.systemBackground)
    static let surfaceSecondary = Color(.secondarySystemBackground)
    static let surfaceTertiary = Color(.tertiarySystemBackground)
    
    // MARK: - Text Colors
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color(.tertiaryLabel)
    static let textInverse = Color(.systemBackground)
    
    // MARK: - Border Colors
    static let border = Color(.separator)
    static let borderLight = Color(.separator).opacity(0.5)
    static let borderDark = Color(.separator).opacity(0.8)
    
    // MARK: - Category Colors (for charts and categorization)
    static let categoryColors: [Color] = [
        Color(red: 0.26, green: 0.54, blue: 0.98),  // Blue
        Color(red: 0.35, green: 0.71, blue: 0.42),  // Green
        Color(red: 0.95, green: 0.54, blue: 0.31),  // Orange
        Color(red: 0.61, green: 0.35, blue: 0.71),  // Purple
        Color(red: 0.96, green: 0.76, blue: 0.19),  // Yellow
        Color(red: 0.96, green: 0.39, blue: 0.44),  // Red
        Color(red: 0.20, green: 0.71, blue: 0.90),  // Cyan
        Color(red: 0.98, green: 0.55, blue: 0.76),  // Pink
        Color(red: 0.60, green: 0.80, blue: 0.20),  // Lime
        Color(red: 0.70, green: 0.53, blue: 0.35),  // Brown
    ]
    
    /// Get a consistent color for a category based on its name
    static func colorForCategory(_ category: String) -> Color {
        let index = abs(category.hashValue) % categoryColors.count
        return categoryColors[index]
    }
    
    // MARK: - Transaction Type Colors
    static let expenseColor = Color.red
    static let incomeColor = Color.green
    
    // MARK: - Chart Colors
    static let chartPrimary = Color.accentColor
    static let chartSecondary = Color.blue
    static let chartTertiary = Color.purple
    static let chartBackground = Color(.secondarySystemBackground)
    static let chartGrid = Color(.separator).opacity(0.3)
}

// MARK: - Gradient Definitions
extension ColorTokens {
    static let primaryGradient = LinearGradient(
        colors: [primary, primary.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let successGradient = LinearGradient(
        colors: [success, success.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let warningGradient = LinearGradient(
        colors: [warning, warning.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
