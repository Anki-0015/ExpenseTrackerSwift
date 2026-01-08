import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email: String
    @State private var isLoading: Bool = false
    @State private var message: String?

    private let auth = AuthService()

    init(email: String) {
        _email = State(initialValue: email)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()

                    Button {
                        Task { await send() }
                    } label: {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("Send reset link")
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
                    Text("We’ll email you a link to reset your password. When you open the link on this device, the app will show a screen to set a new password.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Forgot password")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func send() async {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            message = "Enter your email address."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await auth.sendPasswordResetEmail(email: trimmed, redirectTo: SupabaseConfig.redirectURL)
            message = "Reset email sent. Check your inbox."
        } catch {
            message = error.localizedDescription
        }
    }
}

#Preview {
    ForgotPasswordView(email: "user@example.com")
}
