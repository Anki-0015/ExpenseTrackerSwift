import SwiftUI
import SwiftData

/// Reusable Settings sections (so Settings can live inside Profile).
struct SettingsSectionsView: View {
    @Environment(AppState.self) private var appState

    @Query(sort: \SavingsGoal.createdAt, order: .reverse) private var goals: [SavingsGoal]

    var body: some View {
        Section("Power") {
            NavigationLink("Budgets", destination: BudgetsView())
            NavigationLink("Goals", destination: GoalsView())
        }

        Section("Preferences") {
            TextField("Currency code", text: Binding(
                get: { appState.settings.defaultCurrencyCode },
                set: { newValue in
                    appState.updateSettings { $0.defaultCurrencyCode = newValue.uppercased() }
                }
            ))
            .textInputAutocapitalization(.characters)

            Stepper("Fiscal month start: \(appState.settings.fiscalMonthStartDay)", value: Binding(
                get: { appState.settings.fiscalMonthStartDay },
                set: { newValue in
                    appState.updateSettings { $0.fiscalMonthStartDay = max(1, min(28, newValue)) }
                }
            ), in: 1...28)

            Toggle("Zero-based budgeting", isOn: Binding(
                get: { appState.settings.zeroBasedBudgetEnabled },
                set: { enabled in
                    appState.updateSettings { $0.zeroBasedBudgetEnabled = enabled }
                }
            ))

            Picker("Carry-forward to goal", selection: Binding(
                get: { appState.settings.carryForwardSavingsGoalId },
                set: { newValue in
                    appState.updateSettings { $0.carryForwardSavingsGoalId = newValue }
                }
            )) {
                Text("Carry-forward Savings (default)").tag(UUID?.none)
                ForEach(goals) { goal in
                    Text(goal.name).tag(Optional(goal.id))
                }
            }
        }

        Section("Review reminder") {
            Toggle("Daily review reminder", isOn: Binding(
                get: { appState.settings.reviewReminderEnabled },
                set: { enabled in
                    appState.updateSettings { $0.reviewReminderEnabled = enabled }
                }
            ))

            DatePicker(
                "Time",
                selection: Binding(
                    get: {
                        Calendar.current.date(from: appState.settings.reviewReminderTime) ?? Date()
                    },
                    set: { date in
                        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                        appState.updateSettings { $0.reviewReminderTime = comps }
                    }
                ),
                displayedComponents: [.hourAndMinute]
            )
            .disabled(!appState.settings.reviewReminderEnabled)
        }

        Section("Security") {
            Toggle("App lock", isOn: Binding(
                get: { appState.settings.appLockEnabled },
                set: { enabled in
                    appState.updateSettings { $0.appLockEnabled = enabled }
                }
            ))
        }

        Section("Data") {
            NavigationLink("Export", destination: ExportView())
            NavigationLink("Data integrity", destination: DataIntegrityView())
            NavigationLink("Reset month", destination: ResetView(scope: .month, settings: appState.settings))
            NavigationLink("Reset year", destination: ResetView(scope: .year, settings: appState.settings))
        }
    }
}
