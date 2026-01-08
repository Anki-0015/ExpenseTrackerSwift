import SwiftUI

struct AuthView: View {
    @Environment(AppState.self) private var appState
    @State private var model = AuthViewModel()

    @State private var showForgotPassword: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(model.mode == .signIn ? "Welcome back" : "Create your account")
                            .font(.title.bold())
                        Text(model.mode == .signIn ? "Sign in to sync your profile." : "Sign up to sync your profile across devices.")
                            .foregroundStyle(.secondary)
                    }

                    Picker("Mode", selection: $model.mode) {
                        Text("Sign in").tag(AuthViewModel.Mode.signIn)
                        Text("Sign up").tag(AuthViewModel.Mode.signUp)
                    }
                    .pickerStyle(.segmented)

                    VStack(spacing: 12) {
                        TextField("Email", text: $model.email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocorrectionDisabled()
                            .textFieldStyle(.roundedBorder)

                        SecureField("Password", text: $model.password)
                            .textContentType(model.mode == .signIn ? .password : .newPassword)
                            .textFieldStyle(.roundedBorder)

                        if model.mode == .signUp {
                            TextField("Full name (optional)", text: $model.fullName)
                                .textInputAutocapitalization(.words)
                                .textContentType(.name)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    if model.mode == .signIn {
                        Button("Forgot password?") {
                            showForgotPassword = true
                        }
                        .font(.callout)
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
                                    .font(.headline)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isLoading)

                    if let message = model.message {
                        Text(message)
                            .foregroundStyle(.secondary)
                            .font(.callout)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Text("Before this works, configure Supabase keys in SupabaseConfig and create the profiles table + RLS policies.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle(model.mode == .signIn ? "Sign in" : "Sign up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") {
                        appState.route = .main
                    }
                }
            }
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView(email: model.email)
        }
        .sheet(
            item: Binding(
                get: { appState.authSheet },
                set: { appState.authSheet = $0 }
            )
        ) { sheet in
            switch sheet {
            case .passwordRecovery:
                PasswordRecoveryView()
            }
        }
    }
}

#Preview {
    AuthView()
        .environment(AppState())
}
