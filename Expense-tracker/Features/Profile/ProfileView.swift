import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var model = ProfileViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch model.state {
                case .signedOut:
                    signedOutPlaceholder
                case let .signedIn(_, email):
                    signedIn(email: email)
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if case .signedIn = model.state {
                        Button("Sign out") {
                            Task { await model.signOut() }
                            appState.setSignedOut()
                        }
                    }
                }
            }
            .task {
                await model.loadCurrentUser()
            }
        }
    }

    private var signedOutPlaceholder: some View {
        Form {
            Section {
                Text("You're signed out.")
                    .foregroundStyle(.secondary)

                Button("Sign in") {
                    appState.route = .auth
                }
            }
        }
    }

    private func signedIn(email: String?) -> some View {
        Form {
            Section("Account") {
                HStack {
                    Text("Email")
                    Spacer()
                    Text(email ?? "—")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Profile") {
                TextField("Full name", text: $model.fullName)
                    .textInputAutocapitalization(.words)

                Button {
                    Task { await model.saveProfile() }
                } label: {
                    HStack {
                        Spacer()
                        if model.isLoading {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                        Spacer()
                    }
                }
                .disabled(model.isLoading)
            }

            if let message = model.message {
                Section {
                    Text(message)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environment(AppState())
}
