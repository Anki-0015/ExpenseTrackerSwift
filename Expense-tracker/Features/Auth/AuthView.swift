import SwiftUI

struct AuthView: View {
    @Environment(AppState.self) private var appState
    @State private var model = AuthViewModel()

    @State private var showForgotPassword: Bool = false
    @State private var showPassword: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        ColorTokens.primary.opacity(0.1),
                        Color(.systemBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Header
                        headerSection
                        
                        // Mode Switcher
                        modeSwitcher
                        
                        // Form
                        formSection
                        
                        // Submit Button
                        submitButton
                        
                        // Additional Actions
                        if model.mode == .signIn {
                            forgotPasswordButton
                        }
                        
                        // Message Display
                        if let message = model.message {
                            messageView(message)
                        }
                        
                        Spacer(minLength: Spacing.xl)
                        
                        // Footer Note
                        footerNote
                    }
                    .padding(Spacing.screenPadding)
                    .padding(.top, Spacing.xxl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        appState.route = .auth
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(ColorTokens.textSecondary)
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
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: Spacing.md) {
            // App Icon/Logo
            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                .font(.system(size: 70))
                .foregroundStyle(
                    LinearGradient(
                        colors: [ColorTokens.primary, ColorTokens.primary.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.bottom, Spacing.sm)
            
            VStack(spacing: Spacing.xs) {
                Text(model.mode == .signIn ? "Welcome Back" : "Get Started")
                    .font(Typography.displayMedium)
                    .foregroundStyle(ColorTokens.textPrimary)
                
                Text(model.mode == .signIn ? "Sign in to access your finances" : "Create your account to start tracking")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Mode Switcher
    private var modeSwitcher: some View {
        Picker("Mode", selection: $model.mode.animation(.smooth)) {
            Text("Sign In").tag(AuthViewModel.Mode.signIn)
            Text("Sign Up").tag(AuthViewModel.Mode.signUp)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, Spacing.xl)
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: Spacing.lg) {
            // Email Field
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label("Email", systemImage: "envelope.fill")
                    .font(Typography.titleSmall)
                    .foregroundStyle(ColorTokens.textPrimary)
                
                TextField("your.email@example.com", text: $model.email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                    .padding(Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                            .strokeBorder(ColorTokens.borderLight, lineWidth: Spacing.borderThin)
                    )
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label("Password", systemImage: "lock.fill")
                    .font(Typography.titleSmall)
                    .foregroundStyle(ColorTokens.textPrimary)
                
                HStack(spacing: Spacing.sm) {
                    Group {
                        if showPassword {
                            TextField("Enter your password", text: $model.password)
                        } else {
                            SecureField("Enter your password", text: $model.password)
                        }
                    }
                    .textContentType(model.mode == .signIn ? .password : .newPassword)
                    
                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                }
                .padding(Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                        .fill(Color(.secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                        .strokeBorder(ColorTokens.borderLight, lineWidth: Spacing.borderThin)
                )
            }
            
            // Full Name Field (Sign Up only)
            if model.mode == .signUp {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Label("Full Name (Optional)", systemImage: "person.fill")
                        .font(Typography.titleSmall)
                        .foregroundStyle(ColorTokens.textPrimary)
                    
                    TextField("John Doe", text: $model.fullName)
                        .textInputAutocapitalization(.words)
                        .textContentType(.name)
                        .padding(Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                                .strokeBorder(ColorTokens.borderLight, lineWidth: Spacing.borderThin)
                        )
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        Button {
            Task {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                if let user = await model.submit() {
                    appState.setSignedIn(userId: user.id, email: user.email)
                }
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                if model.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: model.mode == .signIn ? "arrow.right.circle.fill" : "checkmark.circle.fill")
                        .font(.title3)
                    
                    Text(model.mode == .signIn ? "Sign In" : "Create Account")
                        .font(Typography.titleMedium)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                    .fill(
                        LinearGradient(
                            colors: model.isLoading ? 
                                [ColorTokens.primary.opacity(0.6), ColorTokens.primary.opacity(0.6)] :
                                [ColorTokens.primary, ColorTokens.primary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: ColorTokens.primary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(model.isLoading || !isFormValid)
        .opacity(model.isLoading || !isFormValid ? 0.6 : 1.0)
        .animation(.smooth, value: model.isLoading)
    }
    
    // MARK: - Forgot Password Button
    private var forgotPasswordButton: some View {
        Button {
            showForgotPassword = true
        } label: {
            Text("Forgot your password?")
                .font(Typography.bodySmall)
                .foregroundStyle(ColorTokens.primary)
        }
    }
    
    // MARK: - Message View
    private func messageView(_ message: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: message.contains("success") || message.contains("sent") ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(message.contains("success") || message.contains("sent") ? ColorTokens.success : ColorTokens.error)
            
            Text(message)
                .font(Typography.bodySmall)
                .foregroundStyle(ColorTokens.textPrimary)
            
            Spacer()
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                .fill(message.contains("success") || message.contains("sent") ? ColorTokens.successLight : ColorTokens.errorLight)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                .strokeBorder(
                    message.contains("success") || message.contains("sent") ? ColorTokens.success.opacity(0.3) : ColorTokens.error.opacity(0.3),
                    lineWidth: 1
                )
        )
    }
    
    // MARK: - Footer Note
    private var footerNote: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "info.circle.fill")
                    .font(Typography.captionMedium)
                
                Text("Configure Supabase in settings to enable cloud sync")
                    .font(Typography.captionMedium)
            }
            .foregroundStyle(ColorTokens.textTertiary)
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Spacing.lg)
    }
    
    // MARK: - Validation
    private var isFormValid: Bool {
        !model.email.isEmpty && 
        model.email.contains("@") && 
        !model.password.isEmpty && 
        model.password.count >= 6
    }
}

#Preview {
    AuthView()
        .environment(AppState())
}
