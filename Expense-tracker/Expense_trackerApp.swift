//
//  Expense_trackerApp.swift
//  Expense-tracker
//
//  Created by Ankit bansal on 08/01/26.
//

import SwiftUI
import SwiftData

@main
struct Expense_trackerApp: App {
    @State private var appState = AppState()
    private let modelContainer = PersistenceController.makeModelContainer()

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            AppShellView()
            .environment(appState)
            .modelContainer(modelContainer)
            .preferredColorScheme(colorScheme(for: appState.settings.appearance))
            .tint(.accentColor)
            .task {
                let context = modelContainer.mainContext

                // Seed sample data for a richer first-run experience.
                SampleData.seedIfNeeded(modelContext: context, settings: appState.settings)

                // Carry-forward is local + rule-based.
                applyCarryForwardIfNeeded(context: context)

                // Handle reminder setup (optional, local-only).
                await applyReviewReminderSettings()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task {
                        let context = modelContainer.mainContext
                        applyCarryForwardIfNeeded(context: context)
                        await applyReviewReminderSettings()
                    }
                }
            }
        }
    }

    private func colorScheme(for appearance: AppAppearance) -> ColorScheme? {
        switch appearance {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    private func applyReviewReminderSettings() async {
        let reminder = LocalReviewReminder()
        if appState.settings.reviewReminderEnabled {
            await reminder.requestAuthorizationIfNeeded()
            await reminder.scheduleDailyReviewReminder(time: appState.settings.reviewReminderTime)
        } else {
            reminder.cancelDailyReviewReminder()
        }
    }

    private func applyCarryForwardIfNeeded(context: ModelContext) {
        let service = CarryForwardService()
        let currentMonth = DateBuckets.monthKey(for: .now, fiscalStartDay: appState.settings.fiscalMonthStartDay)
        service.applyCarryForward(into: currentMonth, modelContext: context, settings: appState.settings)

        let processing = MonthlyProcessingService()
        processing.upsertFinancialScore(monthKey: currentMonth, modelContext: context, settings: appState.settings)
    }
}
