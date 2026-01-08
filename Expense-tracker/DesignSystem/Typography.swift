import SwiftUI

/// Typography system for consistent text styling
struct Typography {
    
    // MARK: - Display Styles (Largest)
    static let displayLarge: Font = .system(size: 40, weight: .bold, design: .rounded)
    static let displayMedium: Font = .system(size: 34, weight: .bold, design: .rounded)
    static let displaySmall: Font = .system(size: 28, weight: .bold, design: .rounded)
    
    // MARK: - Headline Styles
    static let headlineLarge: Font = .system(size: 24, weight: .semibold, design: .rounded)
    static let headlineMedium: Font = .system(size: 20, weight: .semibold, design: .rounded)
    static let headlineSmall: Font = .system(size: 18, weight: .semibold, design: .rounded)
    
    // MARK: - Title Styles
    static let titleLarge: Font = .system(size: 18, weight: .semibold)
    static let titleMedium: Font = .system(size: 16, weight: .semibold)
    static let titleSmall: Font = .system(size: 14, weight: .semibold)
    
    // MARK: - Body Styles
    static let bodyLarge: Font = .system(size: 17, weight: .regular)
    static let bodyMedium: Font = .system(size: 15, weight: .regular)
    static let bodySmall: Font = .system(size: 13, weight: .regular)
    
    // MARK: - Caption Styles
    static let captionLarge: Font = .system(size: 12, weight: .regular)
    static let captionMedium: Font = .system(size: 11, weight: .regular)
    static let captionSmall: Font = .system(size: 10, weight: .regular)
    
    // MARK: - Special Purpose Fonts
    static let monospaced: Font = .system(.body, design: .monospaced)
    static let currencyLarge: Font = .system(size: 36, weight: .semibold, design: .rounded)
    static let currencyMedium: Font = .system(size: 24, weight: .semibold, design: .rounded)
    static let currencySmall: Font = .system(size: 18, weight: .semibold, design: .rounded)
}

// MARK: - Text Extension for Convenient Usage
extension Text {
    func displayLarge() -> Text {
        self.font(Typography.displayLarge)
    }
    
    func displayMedium() -> Text {
        self.font(Typography.displayMedium)
    }
    
    func displaySmall() -> Text {
        self.font(Typography.displaySmall)
    }
    
    func headlineLarge() -> Text {
        self.font(Typography.headlineLarge)
    }
    
    func headlineMedium() -> Text {
        self.font(Typography.headlineMedium)
    }
    
    func headlineSmall() -> Text {
        self.font(Typography.headlineSmall)
    }
    
    func titleLarge() -> Text {
        self.font(Typography.titleLarge)
    }
    
    func titleMedium() -> Text {
        self.font(Typography.titleMedium)
    }
    
    func titleSmall() -> Text {
        self.font(Typography.titleSmall)
    }
    
    func bodyLarge() -> Text {
        self.font(Typography.bodyLarge)
    }
    
    func bodyMedium() -> Text {
        self.font(Typography.bodyMedium)
    }
    
    func bodySmall() -> Text {
        self.font(Typography.bodySmall)
    }
    
    func captionLarge() -> Text {
        self.font(Typography.captionLarge)
    }
    
    func captionMedium() -> Text {
        self.font(Typography.captionMedium)
    }
    
    func captionSmall() -> Text {
        self.font(Typography.captionSmall)
    }
}
