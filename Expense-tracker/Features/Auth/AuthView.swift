import SwiftUI

struct AuthView: View {
    @Environment(AppState.self) private var appState
    @State private var model = AuthViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Mode", selection: $model.mode) {
                        Text("Sign in").tag(AuthViewModel.Mode.signIn)
                        Text("Sign up").tag(AuthViewModel.Mode.signUp)
                    }
                    .pickerStyle(.segmented)

                    TextField("Email", text: $model.email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()

                    SecureField("Password", text: $model.password)

                    if model.mode == .signUp {
                        TextField("Full name (optional)", text: $model.fullName)
                            .textInputAutocapitalization(.words)
                    }

                    Button {
                        Task {
                            if let user = await model.submit() {
                                appState.setSignedIn(userId: user.id, email: user.email)
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if model.isLoading {
                                ProgressView()
                            } else {
                                Text(model.mode == .signIn ? "Sign in" : "Create account")
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

                Section {
                    Button("Back") {
                        appState.route = .landing
                    }
                }

                Section {
                    Text("Before this works, configure Supabase keys in SupabaseConfig and create the profiles table + RLS policies.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Sign in")
        }
    }
}

#Preview {
    AuthView()
        .environment(AppState())
}
