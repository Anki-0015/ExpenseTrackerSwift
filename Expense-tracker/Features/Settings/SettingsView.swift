import SwiftUI
import LocalAuthentication
import SwiftData

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    @State private var isSigningOut: Bool = false
    @State private var confirmSignOut: Bool = false

    var body: some View {
        NavigationStack {
            List {
                SettingsSectionsView()

                accountSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
        }
    }

    @ViewBuilder
    private var accountSection: some View {
        Section("Account") {
            switch appState.authStatus {
            case .signedIn(_, let email):
                HStack {
                    Text("Signed in")
                    Spacer()
                    Text(email ?? "—")
                        .foregroundStyle(.secondary)
                }

                Button(role: .destructive) {
                    confirmSignOut = true
                } label: {
                    if isSigningOut {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        Text("Sign out")
                    }
                }
                .disabled(isSigningOut)

            case .signedOut, .unknown:
                HStack {
                    Text("Signed out")
                    Spacer()
                    Text("Local mode")
                        .foregroundStyle(.secondary)
                }

                Button("Sign in") {
                    appState.route = .auth
                }
            }
        }
        .confirmationDialog(
            "Sign out?",
            isPresented: $confirmSignOut,
            titleVisibility: .visible
        ) {
            Button("Sign out", role: .destructive) {
                Task { await signOut() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You’ll be taken to the sign in screen. Your local expenses stay on this device.")
        }
    }

    private func signOut() async {
        isSigningOut = true
        defer { isSigningOut = false }

        let auth = AuthService()
        await auth.signOut()
        appState.setSignedOut()
    }
}

struct ExportView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var exportURL: URL?

    var body: some View {
        VStack(spacing: 16) {
            if let exportURL {
                ShareLink(item: exportURL) {
                    Text("Share export")
                }
            }

            Button("Generate JSON export") {
                exportURL = generateExport()
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding(16)
        .navigationTitle("Export")
    }

    private func generateExport() -> URL? {
        let descriptor = FetchDescriptor<Expense>()
        let expenses = (try? modelContext.fetch(descriptor)) ?? []

        let payload: [[String: Any]] = expenses.map {
            [
                "id": $0.id.uuidString,
                "createdAt": $0.createdAt.timeIntervalSince1970,
                "occurredAt": $0.occurredAt.timeIntervalSince1970,
                "kind": $0.kindRaw,
                "approval": $0.approvalRaw,
                "amount": NSDecimalNumber(decimal: $0.amount).stringValue,
                "currency": $0.currencyCode,
                "title": $0.title,
                "notes": $0.notes ?? "",
                "category": $0.category,
                "paymentMethod": $0.paymentMethod,
                "emotionalTag": $0.emotionalTagRaw,
            ]
        }

        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted]) else {
            return nil
        }

        let dir = FileManager.default.temporaryDirectory
        let url = dir.appendingPathComponent("expense-os-export.json")
        try? data.write(to: url, options: [.atomic])
        return url
    }
}

struct DataIntegrityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @State private var selectedDate: Date = .now

    var body: some View {
        let service = DataIntegrityService()
        let monthKey = DateBuckets.monthKey(for: selectedDate, fiscalStartDay: appState.settings.fiscalMonthStartDay)
        let findings = service.runMonthlyHealthCheck(monthKey: monthKey, modelContext: modelContext, currencyCode: appState.settings.defaultCurrencyCode)

        List {
            Section {
                DatePicker("Month", selection: $selectedDate, displayedComponents: [.date])
            }

            Section("Findings") {
                ForEach(findings) { f in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(f.title)
                            .font(.headline)
                        Text(f.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Data Integrity")
    }
}

enum ResetScope: String {
    case month
    case year
}

struct ResetView: View {
    @Environment(\.modelContext) private var modelContext

    let scope: ResetScope
    let settings: AppSettings

    @State private var confirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("This deletes expenses (and related derived data) locally. This cannot be undone.")
                .foregroundStyle(.secondary)

            Toggle("I understand", isOn: $confirm)

            Button(role: .destructive) {
                reset()
            } label: {
                Text("Reset \(scope.rawValue)")
                    .frame(maxWidth: .infinity)
            }
            .disabled(!confirm)
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding(16)
        .navigationTitle("Reset")
    }

    private func reset() {
        let now = Date()
        let calendar = Calendar.current

        let range: (start: Date, end: Date) = {
            switch scope {
            case .month:
                return DateBuckets.monthRange(for: now, fiscalStartDay: settings.fiscalMonthStartDay, calendar: calendar)
            case .year:
                let start = calendar.date(from: calendar.dateComponents([.year], from: now)) ?? now
                let end = calendar.date(byAdding: .year, value: 1, to: start) ?? now
                return (start, end)
            }
        }()

        let start = range.start
        let end = range.end

        let descriptor = FetchDescriptor<Expense>(predicate: #Predicate<Expense> { exp in
            exp.occurredAt >= start && exp.occurredAt < end
        })
        let items = (try? modelContext.fetch(descriptor)) ?? []
        for e in items { modelContext.delete(e) }
    }
}
