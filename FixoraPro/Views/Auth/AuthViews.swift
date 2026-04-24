import SwiftUI

// MARK: - Welcome
struct WelcomeView: View {
    @State private var showLogin = false
    @State private var showRegister = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            GridBackgroundView(animate: false).opacity(0.12).ignoresSafeArea()

            // Gradient orbs
            Circle()
                .fill(Color.accentCyan.opacity(0.08))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: -80, y: -200)

            Circle()
                .fill(Color.accentPurple.opacity(0.06))
                .frame(width: 250, height: 250)
                .blur(radius: 60)
                .offset(x: 100, y: 200)

            VStack(spacing: 0) {
                Spacer()

                // Logo
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(LinearGradient(colors: [Color.cardBg2, Color.bgSoft], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 88, height: 88)
                            .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.accentCyan.opacity(0.4), lineWidth: 1.5))
                            .cyanGlow(radius: 12)

                        CableIconView(progress: 1.0)
                            .frame(width: 52, height: 52)
                    }
                    .scaleEffect(appeared ? 1 : 0.7)
                    .opacity(appeared ? 1 : 0)

                    HStack(spacing: 0) {
                        Text("Fixora")
                            .font(FixoraFont.display(40))
                            .foregroundColor(Color.textPrimary)
                        Text(" Pro")
                            .font(FixoraFont.display(40))
                            .foregroundColor(Color.accentCyan)
                            .cyanGlow(radius: 12)
                    }
                    .offset(y: appeared ? 0 : 30)
                    .opacity(appeared ? 1 : 0)

                    Text("Map every cable. Drill with confidence.")
                        .font(FixoraFont.body(16))
                        .foregroundColor(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                }

                Spacer()

                // Buttons
                VStack(spacing: 14) {
                    Button("Start — Create Account") {
                        showRegister = true
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button("Log In") {
                        showLogin = true
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
                .offset(y: appeared ? 0 : 40)
                .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.1)) {
                appeared = true
            }
        }
        .sheet(isPresented: $showLogin) { LoginView() }
        .sheet(isPresented: $showRegister) { RegisterView() }
    }
}

// MARK: - Login
struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var name = ""
    @State private var showError = false
    @State private var loading = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgMain.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 52))
                                .foregroundColor(Color.accentCyan)
                                .cyanGlow()

                            Text("Welcome Back")
                                .font(FixoraFont.heading(26))
                                .foregroundColor(Color.textPrimary)

                            Text("Sign in to continue")
                                .font(FixoraFont.body(15))
                                .foregroundColor(Color.textInactive)
                        }
                        .padding(.top, 20)

                        // Form
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your Name")
                                    .font(FixoraFont.caption(13))
                                    .foregroundColor(Color.textSecondary)
                                TextField("John Smith", text: $name)
                                    .textFieldStyle(FixoraTextFieldStyle())
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(FixoraFont.caption(13))
                                    .foregroundColor(Color.textSecondary)
                                TextField("you@example.com", text: $email)
                                    .textFieldStyle(FixoraTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                        }
                        .padding(.horizontal, 24)

                        if showError {
                            Text("Please fill in all fields")
                                .font(FixoraFont.caption(13))
                                .foregroundColor(Color.statusDanger)
                        }

                        // Login button
                        VStack(spacing: 12) {
                            Button(loading ? "Signing In..." : "Sign In") {
                                attemptLogin()
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(loading)
                            .padding(.horizontal, 24)

                            // Demo Button
                            Button {
                                demoLogin()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "play.circle.fill")
                                        .foregroundColor(Color.accentCyan)
                                    Text("Continue with Demo Account")
                                        .font(FixoraFont.subheading(15))
                                        .foregroundColor(Color.accentCyan)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.accentCyan.opacity(0.1))
                                .cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.accentCyan.opacity(0.4), lineWidth: 1.5))
                            }
                            .padding(.horizontal, 24)
                            .cyanGlow(radius: 6)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.accentCyan)
                }
            }
        }
    }

    private func attemptLogin() {
        guard !name.isEmpty, !email.isEmpty else {
            showError = true
            return
        }
        loading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            appState.login(name: name, email: email)
            dismiss()
        }
    }

    private func demoLogin() {
        loading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            appState.loginDemo()
            dismiss()
        }
    }
}

// MARK: - Register
struct RegisterView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var showError = false
    @State private var loading = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgMain.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        VStack(spacing: 8) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 52))
                                .foregroundColor(Color.accentCyan)
                                .cyanGlow()

                            Text("Create Account")
                                .font(FixoraFont.heading(26))
                                .foregroundColor(Color.textPrimary)
                        }
                        .padding(.top, 20)

                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Full Name")
                                    .font(FixoraFont.caption(13))
                                    .foregroundColor(Color.textSecondary)
                                TextField("John Smith", text: $name)
                                    .textFieldStyle(FixoraTextFieldStyle())
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(FixoraFont.caption(13))
                                    .foregroundColor(Color.textSecondary)
                                TextField("you@example.com", text: $email)
                                    .textFieldStyle(FixoraTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                        }
                        .padding(.horizontal, 24)

                        if showError {
                            Text("Please fill in all fields")
                                .font(FixoraFont.caption(13))
                                .foregroundColor(Color.statusDanger)
                        }

                        VStack(spacing: 12) {
                            Button(loading ? "Creating..." : "Create Account") {
                                guard !name.isEmpty, !email.isEmpty else { showError = true; return }
                                loading = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    appState.login(name: name, email: email)
                                    dismiss()
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(.horizontal, 24)

                            Button {
                                appState.loginDemo()
                                dismiss()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "play.circle.fill")
                                        .foregroundColor(Color.accentCyan)
                                    Text("Try Demo Account")
                                        .font(FixoraFont.subheading(15))
                                        .foregroundColor(Color.accentCyan)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.accentCyan.opacity(0.1))
                                .cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.accentCyan.opacity(0.4), lineWidth: 1.5))
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.accentCyan)
                }
            }
        }
    }
}
