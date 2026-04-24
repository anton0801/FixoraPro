import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settingsVM: SettingsViewModel
    @State private var showProfile = false
    @State private var showDeleteAlert = false
    @State private var showLogoutAlert = false
    @State private var saveToast = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Profile card
                        Button {
                            showProfile = true
                        } label: {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(colors: [Color.accentCyan, Color.accentPurple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 56, height: 56)

                                    Text(String(appState.currentUserName.prefix(1)).uppercased())
                                        .font(FixoraFont.display(22))
                                        .foregroundColor(Color.bgPrimary)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text(appState.currentUserName)
                                            .font(FixoraFont.subheading(16))
                                            .foregroundColor(Color.textPrimary)
                                        if appState.isDemoAccount {
                                            Text("DEMO")
                                                .font(FixoraFont.caption(9))
                                                .foregroundColor(Color.bgPrimary)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.accentCyan)
                                                .cornerRadius(4)
                                        }
                                    }
                                    Text(appState.currentUserEmail)
                                        .font(FixoraFont.caption(13))
                                        .foregroundColor(Color.textInactive)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.textInactive)
                            }
                            .cardStyle()
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Appearance
                        SettingsSection(title: "Appearance") {
                            VStack(spacing: 0) {
                                SettingsRow(icon: "moon.fill", iconColor: .accentPurple, title: "Theme") {
                                    Picker("Theme", selection: $settingsVM.themeMode) {
                                        Text("System").tag("system")
                                        Text("Dark").tag("dark")
                                        Text("Light").tag("light")
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 180)
                                }

                                Divider().background(Color.divider).padding(.leading, 52)
                            }
                        }

                        // Map Settings
                        SettingsSection(title: "Map Settings") {
                            VStack(spacing: 0) {
                                SettingsToggleRow(
                                    icon: "grid", iconColor: .accentCyan,
                                    title: "Show Grid",
                                    isOn: $settingsVM.showGrid
                                )
                                Divider().background(Color.divider).padding(.leading, 52)

                                SettingsToggleRow(
                                    icon: "square.grid.3x3", iconColor: .accentCyanLight,
                                    title: "Snap to Grid",
                                    isOn: $settingsVM.snapToGrid
                                )
                                Divider().background(Color.divider).padding(.leading, 52)

                                SettingsToggleRow(
                                    icon: "arrow.down.to.line", iconColor: .accentPurpleSoft,
                                    title: "Show Depth Labels",
                                    isOn: $settingsVM.showDepthLabels
                                )
                                Divider().background(Color.divider).padding(.leading, 52)

                                SettingsRow(icon: "ruler", iconColor: .accentCyan, title: "Grid Size") {
                                    HStack(spacing: 8) {
                                        Text("\(Int(settingsVM.gridSize))px")
                                            .font(FixoraFont.mono(13))
                                            .foregroundColor(Color.accentCyan)
                                        Stepper("", value: $settingsVM.gridSize, in: 10...50, step: 5)
                                            .labelsHidden()
                                    }
                                }
                            }
                        }

                        // Measurements
                        SettingsSection(title: "Measurements") {
                            VStack(spacing: 0) {
                                SettingsRow(icon: "ruler.fill", iconColor: .cableElectric, title: "Units") {
                                    Picker("Units", selection: $settingsVM.measurementUnit) {
                                        Text("Metric (m)").tag("metric")
                                        Text("Imperial (ft)").tag("imperial")
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 180)
                                }

                                Divider().background(Color.divider).padding(.leading, 52)

                                SettingsRow(icon: "arrow.down.to.line.compact", iconColor: .accentPurple, title: "Default Depth") {
                                    HStack(spacing: 6) {
                                        Text(String(format: "%.1f cm", settingsVM.defaultDepth))
                                            .font(FixoraFont.mono(13))
                                            .foregroundColor(Color.accentPurple)
                                        Stepper("", value: $settingsVM.defaultDepth, in: 0.5...15, step: 0.5)
                                            .labelsHidden()
                                    }
                                }
                            }
                        }

                        // Default cable type
                        SettingsSection(title: "Cable Defaults") {
                            VStack(spacing: 0) {
                                SettingsRow(icon: "bolt.fill", iconColor: .cableElectric, title: "Default Type") {
                                    Picker("Type", selection: $settingsVM.defaultCableTypeRaw) {
                                        ForEach(CableType.allCases, id: \.self) { type in
                                            Text(type.rawValue).tag(type.rawValue)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .foregroundColor(Color.accentCyan)
                                }

                                Divider().background(Color.divider).padding(.leading, 52)

                                SettingsRow(icon: "square.and.arrow.up", iconColor: .accentCyanLight, title: "Export Format") {
                                    Picker("Format", selection: $settingsVM.exportFormat) {
                                        Text("PDF").tag("PDF")
                                        Text("PNG").tag("PNG")
                                        Text("JSON").tag("JSON")
                                    }
                                    .pickerStyle(.menu)
                                    .foregroundColor(Color.accentCyan)
                                }
                            }
                        }

                        // Notifications
                        SettingsSection(title: "Notifications") {
                            SettingsToggleRow(
                                icon: "bell.fill", iconColor: .accentCyan,
                                title: "Enable Notifications",
                                isOn: $settingsVM.notificationsEnabled
                            )
                        }

                        // Account
                        SettingsSection(title: "Account") {
                            VStack(spacing: 0) {
                                Button {
                                    showLogoutAlert = true
                                } label: {
                                    HStack(spacing: 14) {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .font(.system(size: 16))
                                            .foregroundColor(Color.statusWarning)
                                            .frame(width: 32, height: 32)
                                            .background(Color.statusWarning.opacity(0.1))
                                            .cornerRadius(8)

                                        Text("Log Out")
                                            .font(FixoraFont.body(15))
                                            .foregroundColor(Color.statusWarning)

                                        Spacer()
                                    }
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 16)
                                }
                                .buttonStyle(PlainButtonStyle())

                                Divider().background(Color.divider).padding(.leading, 62)

                                Button {
                                    showDeleteAlert = true
                                } label: {
                                    HStack(spacing: 14) {
                                        Image(systemName: "person.crop.circle.badge.minus")
                                            .font(.system(size: 16))
                                            .foregroundColor(Color.statusDanger)
                                            .frame(width: 32, height: 32)
                                            .background(Color.statusDanger.opacity(0.1))
                                            .cornerRadius(8)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Delete Account")
                                                .font(FixoraFont.body(15))
                                                .foregroundColor(Color.statusDanger)
                                            Text("All data will be permanently deleted")
                                                .font(FixoraFont.caption(12))
                                                .foregroundColor(Color.statusDanger.opacity(0.7))
                                        }

                                        Spacer()
                                    }
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 16)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }

                        // App info
                        VStack(spacing: 4) {
                            Text("Fixora Pro")
                                .font(FixoraFont.subheading(14))
                                .foregroundColor(Color.textInactive)
                            Text("Version 1.0.0")
                                .font(FixoraFont.caption(12))
                                .foregroundColor(Color.textInactive)
                        }
                        .padding(.vertical, 8)

                        Spacer().frame(height: 80)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }

                // Toast
                if saveToast {
                    VStack {
                        Spacer()
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(Color.statusSafe)
                            Text("Settings saved").font(FixoraFont.subheading(14)).foregroundColor(Color.textPrimary)
                        }
                        .padding(16)
                        .background(Color.cardBg2)
                        .cornerRadius(14)
                        .darkShadow()
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: saveToast)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.bgPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .sheet(isPresented: $showProfile) { ProfileView() }
        .alert("Log Out", isPresented: $showLogoutAlert) {
            Button("Log Out", role: .destructive) {
                withAnimation { appState.logout() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to log out?")
        }
        .alert("Delete Account", isPresented: $showDeleteAlert) {
            Button("Delete Everything", role: .destructive) {
                withAnimation { appState.deleteAccount() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your account and ALL cable data. This action cannot be undone.")
        }
    }
}

// MARK: - Settings Components
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(FixoraFont.caption(11))
                .foregroundColor(Color.textInactive)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content
            }
            .background(Color.cardBg)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.divider.opacity(0.5), lineWidth: 1))
        }
    }
}

struct SettingsRow<Control: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    @ViewBuilder let control: Control

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.1))
                .cornerRadius(8)

            Text(title)
                .font(FixoraFont.body(15))
                .foregroundColor(Color.textPrimary)

            Spacer()

            control
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.1))
                .cornerRadius(8)

            Text(title)
                .font(FixoraFont.body(15))
                .foregroundColor(Color.textPrimary)

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color.accentCyan))
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var saved = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgMain.ignoresSafeArea()

                VStack(spacing: 28) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [Color.accentCyan, Color.accentPurple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 80, height: 80)
                        Text(String(name.prefix(1)).uppercased())
                            .font(FixoraFont.display(32))
                            .foregroundColor(Color.bgPrimary)
                    }
                    .padding(.top, 20)
                    .cyanGlow(radius: 16)

                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(FixoraFont.caption(13))
                                .foregroundColor(Color.textSecondary)
                            TextField("Your name", text: $name)
                                .textFieldStyle(FixoraTextFieldStyle())
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(FixoraFont.caption(13))
                                .foregroundColor(Color.textSecondary)
                            TextField("Your email", text: $email)
                                .textFieldStyle(FixoraTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                    }
                    .padding(.horizontal, 24)

                    if saved {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.statusSafe)
                            Text("Profile saved!")
                                .font(FixoraFont.subheading(14))
                                .foregroundColor(Color.statusSafe)
                        }
                        .transition(.opacity)
                    }

                    Button("Save Profile") {
                        appState.currentUserName = name
                        appState.currentUserEmail = email
                        withAnimation { saved = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { saved = false }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 24)
                    .disabled(name.isEmpty)
                    .opacity(name.isEmpty ? 0.5 : 1)

                    Spacer()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.bgMain, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color.accentCyan)
                }
            }
            .onAppear {
                name = appState.currentUserName
                email = appState.currentUserEmail
            }
        }
    }
}
