import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var model = ProfileViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                Group {
                    switch model.state {
                    case .signedOut:
                        signedOutView
                    case let .signedIn(_, email):
                        signedInView(email: email)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .task {
                await model.loadCurrentUser()
            }
        }
    }

    // MARK: - Signed Out View
    private var signedOutView: some View {
        VStack(spacing: Spacing.xxl) {
            Spacer()
            
            VStack(spacing: Spacing.xl) {
                // Icon
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ColorTokens.textSecondary, ColorTokens.textTertiary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(spacing: Spacing.sm) {
                    Text("Not Signed In")
                        .font(Typography.headlineLarge)
                        .foregroundStyle(ColorTokens.textPrimary)
                    
                    Text("Sign in to sync your profile and access your data across devices")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xxl)
                }
                
                Button {
                    appState.route = .auth
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "person.circle.fill")
                            .font(.title3)
                        Text("Sign In")
                            .font(Typography.titleMedium)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: 280)
                    .padding(.vertical, Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                            .fill(
                                LinearGradient(
                                    colors: [ColorTokens.primary, ColorTokens.primary.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: ColorTokens.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.top, Spacing.md)
            }
            
            Spacer()
            Spacer()
        }
    }

    // MARK: - Signed In View
    private func signedInView(email: String?) -> some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Header Card with Avatar
                headerCard(email: email)
                
                // Profile Information
                profileInfoCard
                
                // Quick Stats
                quickStatsCard
                
                // Message Display
                if let message = model.message {
                    messageCard(message)
                }
                
                Spacer(minLength: Spacing.xl)
            }
            .padding(Spacing.screenPadding)
            .padding(.top, Spacing.sm)
        }
    }
    
    // MARK: - Header Card
    private func headerCard(email: String?) -> some View {
        VStack(spacing: Spacing.lg) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [ColorTokens.primary.opacity(0.2), ColorTokens.primary.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Text(getInitials(from: model.fullName.isEmpty ? (email ?? "U") : model.fullName))
                    .font(Typography.displaySmall)
                    .foregroundStyle(ColorTokens.primary)
            }
            .overlay(
                Circle()
                    .strokeBorder(ColorTokens.primary.opacity(0.3), lineWidth: 2)
            )
            
            VStack(spacing: Spacing.xs) {
                Text(model.fullName.isEmpty ? "User" : model.fullName)
                    .font(Typography.headlineLarge)
                    .foregroundStyle(ColorTokens.textPrimary)
                
                if let email {
                    Text(email)
                        .font(Typography.bodySmall)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: Spacing.radiusLarge)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.radiusLarge)
                .strokeBorder(ColorTokens.borderLight, lineWidth: Spacing.borderThin)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Profile Info Card
    private var profileInfoCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Personal Information")
                .font(Typography.headlineSmall)
                .foregroundStyle(ColorTokens.textPrimary)
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label("Full Name", systemImage: "person.fill")
                    .font(Typography.titleSmall)
                    .foregroundStyle(ColorTokens.textPrimary)
                
                TextField("Enter your name", text: $model.fullName)
                    .textInputAutocapitalization(.words)
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
            
            Button {
                Task {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    await model.saveProfile()
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    if model.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                        Text("Save Changes")
                            .font(Typography.titleSmall)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                        .fill(model.isLoading ? ColorTokens.primary.opacity(0.6) : ColorTokens.primary)
                )
            }
            .disabled(model.isLoading)
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Spacing.radiusLarge)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.radiusLarge)
                .strokeBorder(ColorTokens.borderLight, lineWidth: Spacing.borderThin)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Quick Stats Card
    private var quickStatsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Account Status")
                .font(Typography.headlineSmall)
                .foregroundStyle(ColorTokens.textPrimary)
            
            HStack(spacing: Spacing.md) {
                statusItem(
                    icon: "checkmark.shield.fill",
                    title: "Verified",
                    subtitle: "Account Active",
                    color: ColorTokens.success
                )
                
                statusItem(
                    icon: "lock.shield.fill",
                    title: "Secure",
                    subtitle: "Protected",
                    color: ColorTokens.info
                )
            }
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Spacing.radiusLarge)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.radiusLarge)
                .strokeBorder(ColorTokens.borderLight, lineWidth: Spacing.borderThin)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    @ViewBuilder
    private func statusItem(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(Typography.titleSmall)
                    .foregroundStyle(ColorTokens.textPrimary)
                
                Text(subtitle)
                    .font(Typography.captionMedium)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    // MARK: - Message Card
    private func messageCard(_ message: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: message.lowercased().contains("success") || message.lowercased().contains("saved") ? "checkmark.circle.fill" : "info.circle.fill")
                .foregroundStyle(message.lowercased().contains("success") || message.lowercased().contains("saved") ? ColorTokens.success : ColorTokens.info)
            
            Text(message)
                .font(Typography.bodySmall)
                .foregroundStyle(ColorTokens.textPrimary)
            
            Spacer()
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                .fill(message.lowercased().contains("success") || message.lowercased().contains("saved") ? ColorTokens.successLight : ColorTokens.infoLight)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                .strokeBorder(
                    message.lowercased().contains("success") || message.lowercased().contains("saved") ? ColorTokens.success.opacity(0.3) : ColorTokens.info.opacity(0.3),
                    lineWidth: 1
                )
        )
    }
    
    // MARK: - Helper Functions
    private func getInitials(from name: String) -> String {
        let components = name.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }
}

#Preview {
    ProfileView()
        .environment(AppState())
}
