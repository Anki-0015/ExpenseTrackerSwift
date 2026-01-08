# Expense Tracker

A comprehensive personal finance management app built with SwiftUI and SwiftData, designed to help you track expenses, manage budgets, and gain insights into your spending patterns.

## Features

### 📊 Dashboard
- **Financial Health Score**: Visual ring display showing your overall financial health score for the current month
- **Quick Stats**: At-a-glance view of:
  - Total spending for the month
  - Average spending per day
  - Logging streak (consecutive days with expenses logged)
- **Recent Expenses**: Quick view of your 10 most recent transactions
- **Quick Templates**: Fast expense entry using predefined templates
- **Insights Card**: AI-powered insights about your spending behavior

### 💰 Expense Management
- **Add Expenses**: Quick and easy expense tracking with:
  - Amount and category
  - Date and time selection
  - Notes and descriptions
  - Emotional tagging (neutral, stressed, happy)
  - Currency support
- **Approval System**: Three-state approval workflow:
  - Pending: Expenses awaiting review
  - Approved: Confirmed expenses
  - Discarded: Rejected/cancelled expenses
- **Expense Templates**: Save frequently used expenses as templates for quick entry
- **Income Tracking**: Track both expenses and income transactions

### ✅ Review System
- **Pending Approval Queue**: Review and approve or discard pending transactions
- **Batch Operations**: Efficiently manage multiple pending expenses
- **Daily Review Reminders**: Optional local notifications to remind you to review expenses

### 📅 Timeline View
- **Chronological View**: View all expenses in chronological order
- **Fiscal Month View**: Customizable fiscal month start day
- **Time Bucket Analysis**: Expenses categorized by time of day:
  - Morning (5 AM - 12 PM)
  - Afternoon (12 PM - 5 PM)
  - Evening (5 PM - 10 PM)
  - Night (10 PM - 5 AM)

### 💼 Budget Management
- **Category-based Budgets**: Set spending limits for different expense categories
- **Zero-based Budgeting**: Optional zero-based budgeting system where you assign every dollar of income
- **Budget Tracking**: Real-time tracking of budget vs. actual spending
- **Carry Forward Rules**: Per-category rules for handling unspent budget:
  - Carry to next month
  - Save to goals
  - Don't carry forward
- **Monthly Budget Planning**: Create and manage budgets for each fiscal month

### 🎯 Savings Goals
- **Goal Setting**: Create and track savings goals
- **Goal Allocation**: Allocate surplus budget to specific goals
- **Progress Tracking**: Visual progress indicators for each goal
- **Multiple Goals**: Support for multiple concurrent savings goals
- **Carry Forward Integration**: Auto-allocate unspent budget to designated savings goals

### 📈 Financial Health Scoring
- **Automated Scoring**: Monthly financial health score calculation based on:
  - Budget adherence
  - Spending patterns
  - Savings behavior
  - Transaction consistency
- **Historical Tracking**: Track score changes over time
- **Score Explanation**: Understand what impacts your financial health

### 🧠 Intelligent Insights
- **Mood Correlation**: Identify stress-related spending patterns
- **Category Analysis**: Get insights on spending concentration across categories
- **Volatility Detection**: Track changes in spending consistency month-over-month
- **Personalized Recommendations**: Actionable advice based on your spending behavior

### 🔄 Carry Forward System
- **Automatic Carry Forward**: Unspent budget automatically carried to next month or savings
- **Event Tracking**: Complete audit trail of all carry forward events
- **Customizable Rules**: Configure carry forward behavior per category
- **Savings Integration**: Direct carry forward to specific savings goals

### 👤 User Profile
- **Profile Management**: User profile with personal information
- **Authentication**: Built-in authentication system with Supabase integration
- **Account Settings**: Manage your account and preferences

### ⚙️ Settings & Customization
- **Currency Settings**: Set default currency (supports multiple currencies)
- **Fiscal Month Start**: Customize fiscal month start day (1-28)
- **Appearance**: Choose between System, Light, or Dark mode
- **App Lock**: Biometric authentication (Face ID/Touch ID) for app access
- **Review Reminders**: Configure daily review reminder time
- **Zero-based Budget Toggle**: Enable/disable zero-based budgeting
- **Data Management**: Complete control over your financial data

### 🔒 Security & Privacy
- **Local-First**: All data stored locally using SwiftData
- **App Lock**: Biometric authentication support
- **Data Isolation**: Your data stays on your device
- **Optional Cloud Sync**: Supabase integration for backup (optional)

### 🎨 Design & User Experience
- **Glass Morphism UI**: Modern, beautiful glassmorphic design system
- **Dark Mode Support**: Full dark mode implementation
- **Responsive Design**: Optimized for all iOS devices
- **Smooth Animations**: Polished transitions and interactions
- **Accessibility**: VoiceOver and accessibility labels throughout

### 🔧 Data Management
- **Data Integrity Service**: Automatic data validation and cleanup
- **Sample Data**: Pre-populated sample data for new users to explore features
- **Smart Defaults**: Intelligent default values based on usage patterns
- **Export/Import**: (Planned) Data export and import capabilities

### 📊 Analytics & Reporting
- **Monthly Processing**: Automated monthly financial summaries
- **Streak Tracking**: Track consecutive days of expense logging
- **Spending Trends**: Visualize spending patterns over time
- **Category Breakdown**: Detailed category-wise spending analysis

## Technical Stack

- **Framework**: SwiftUI
- **Data Persistence**: SwiftData
- **Backend (Optional)**: Supabase
- **Authentication**: Supabase Auth / Local Auth
- **Notifications**: UserNotifications framework
- **Biometrics**: LocalAuthentication framework
- **Minimum iOS Version**: iOS 17.0+

## Project Structure

```
Expense-tracker/
├── App/                        # App-level components
│   ├── AppShellView.swift      # Main app shell
│   ├── AppState.swift          # Global app state
│   ├── RootView.swift          # Root tab navigation
│   └── SampleData.swift        # Sample data generation
├── Core/                       # Core business logic
│   ├── Models/                 # Data models
│   │   ├── Expense.swift
│   │   ├── Budget.swift
│   │   ├── SavingsGoal.swift
│   │   └── AppSettings.swift
│   ├── Services/               # Business services
│   │   ├── InsightsEngine.swift
│   │   ├── FinancialHealthScoring.swift
│   │   ├── CarryForwardService.swift
│   │   └── AuthService.swift
│   └── Persistence/            # Data persistence
├── Features/                   # Feature modules
│   ├── Dashboard/              # Dashboard view
│   ├── AddExpense/             # Expense entry
│   ├── Review/                 # Approval workflow
│   ├── Timeline/               # Chronological view
│   ├── Budgets/                # Budget management
│   ├── Goals/                  # Savings goals
│   ├── Profile/                # User profile
│   └── Settings/               # App settings
└── DesignSystem/               # UI components & styling
```

## Getting Started

1. Clone the repository
2. Open `Expense-tracker.xcodeproj` in Xcode
3. Build and run on iOS 17.0+ device or simulator
4. Explore the sample data or start adding your own expenses

## Configuration

The app uses local storage by default. For cloud sync and authentication:

1. Set up a Supabase project
2. Configure `SupabaseConfig.swift` with your project credentials
3. Enable authentication in settings

## License

[Your License Here]

## Author

Ankit Bansal
