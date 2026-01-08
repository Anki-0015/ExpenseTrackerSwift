import SwiftUI

struct PasswordRecoveryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""

    @State private var isLoading: Bool = false
    @State private var message: String?

    private let auth = AuthService()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("New password", text: $newPassword)
                    SecureField("Confirm password", text: $confirmPassword)

                    Button {
                        Task { await updatePassword() }
                    } label: {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("Update password")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isLoading)
                }

                if let message {
                    Section {
                        Text(message)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Text("This screen appears after you open the password recovery link from your email on this device.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Reset password")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        appState.authSheet = nil
                        dismiss()
                    }
                }
            }
        }
    }

    private func updatePassword() async {
        let p1 = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let p2 = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !p1.isEmpty, !p2.isEmpty else {
            message = "Enter and confirm your new password."
            return
        }

        guard p1 == p2 else {
            message = "Passwords don’t match."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await auth.updatePassword(newPassword: p1)
            message = nil
            appState.authSheet = nil
            appState.route = .main
            dismiss()
        } catch {
            message = error.localizedDescription
        }
    }
}

#Preview {
    PasswordRecoveryView()
        .environment(AppState())
}
