import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @State private var appeared = false
    @State private var showReports = false
    @State private var showHistory = false
    @State private var showNotifications = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                GridBackgroundView(animate: false).opacity(0.08).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Hello, \(appState.currentUserName.components(separatedBy: " ").first ?? "there")!")
                                    .font(FixoraFont.heading(22))
                                    .foregroundColor(Color.textPrimary)
                                Text("Your cable map overview")
                                    .font(FixoraFont.body(14))
                                    .foregroundColor(Color.textInactive)
                            }

                            Spacer()

                            Button {
                                showNotifications = true
                            } label: {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: "bell.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(Color.textSecondary)
                                        .padding(10)
                                        .background(Color.cardBg)
                                        .cornerRadius(12)

                                    if !projectsVM.notifications.filter({ $0.isEnabled }).isEmpty {
                                        Circle()
                                            .fill(Color.statusDanger)
                                            .frame(width: 8, height: 8)
                                            .offset(x: -2, y: 2)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .offset(y: appeared ? 0 : -20)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)

                        // Stats row
                        HStack(spacing: 12) {
                            DashboardStatCard(
                                value: "\(projectsVM.projects.count)",
                                label: "Projects",
                                icon: "folder.fill",
                                color: .accentCyan
                            )
                            DashboardStatCard(
                                value: "\(projectsVM.rooms.count)",
                                label: "Rooms",
                                icon: "square.split.2x2.fill",
                                color: .accentPurple
                            )
                            DashboardStatCard(
                                value: "\(projectsVM.totalCables)",
                                label: "Cables",
                                icon: "bolt.fill",
                                color: .cableElectric
                            )
                        }
                        .padding(.horizontal, 20)
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: appeared)

                        // Cable types breakdown
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("Cable Types")
                                    .font(FixoraFont.subheading(16))
                                    .foregroundColor(Color.textPrimary)
                                Spacer()
                                Button {
                                    showReports = true
                                } label: {
                                    Text("Full Report")
                                        .font(FixoraFont.caption(13))
                                        .foregroundColor(Color.accentCyan)
                                }
                            }

                            ForEach(projectsVM.cableCountByType, id: \.0) { type, count in
                                CableTypeRow(type: type, count: count, total: max(projectsVM.totalCables, 1))
                            }
                        }
                        .cardStyle()
                        .padding(.horizontal, 20)
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: appeared)

                        // Safety status
                        let dangerCount = projectsVM.rooms.flatMap { $0.safetyZones }.filter { $0.severity == .danger }.count
                        let warningCount = projectsVM.rooms.flatMap { $0.safetyZones }.filter { $0.severity == .warning }.count

                        VStack(alignment: .leading, spacing: 14) {
                            Text("Safety Status")
                                .font(FixoraFont.subheading(16))
                                .foregroundColor(Color.textPrimary)

                            HStack(spacing: 12) {
                                SafetyStatusBadge(count: dangerCount, label: "Danger Zones", color: .statusDanger, icon: "exclamationmark.triangle.fill")
                                SafetyStatusBadge(count: warningCount, label: "Warnings", color: .statusWarning, icon: "exclamationmark.circle.fill")
                                SafetyStatusBadge(count: projectsVM.totalPoints, label: "Points", color: .pointActive, icon: "powerplug.fill")
                            }
                        }
                        .cardStyle()
                        .padding(.horizontal, 20)
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.25), value: appeared)

                        // Recent Rooms
                        if !projectsVM.recentRooms.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Text("Recent Rooms")
                                        .font(FixoraFont.subheading(16))
                                        .foregroundColor(Color.textPrimary)
                                    Spacer()
                                    Button {
                                        showHistory = true
                                    } label: {
                                        Text("History")
                                            .font(FixoraFont.caption(13))
                                            .foregroundColor(Color.accentCyan)
                                    }
                                }

                                ForEach(projectsVM.recentRooms) { room in
                                    NavigationLink(destination: RoomDetailView(room: room)) {
                                        RecentRoomRow(room: room)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .cardStyle()
                            .padding(.horizontal, 20)
                            .offset(y: appeared ? 0 : 20)
                            .opacity(appeared ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: appeared)
                        }

                        // Bottom padding for tab bar
                        Spacer().frame(height: 80)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showReports) { ReportsView() }
        .sheet(isPresented: $showHistory) { HistoryView() }
        .sheet(isPresented: $showNotifications) { NotificationsView() }
        .onAppear {
            withAnimation { appeared = true }
        }
    }
}

struct DashboardStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)

            Text(value)
                .font(FixoraFont.display(24))
                .foregroundColor(Color.textPrimary)

            Text(label)
                .font(FixoraFont.caption(11))
                .foregroundColor(Color.textInactive)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.cardBg)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct CableTypeRow: View {
    let type: CableType
    let count: Int
    let total: Int

    var fraction: Double { Double(count) / Double(total) }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.system(size: 14))
                .foregroundColor(type.color)
                .frame(width: 28, height: 28)
                .background(type.color.opacity(0.12))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(type.rawValue)
                        .font(FixoraFont.subheading(13))
                        .foregroundColor(Color.textPrimary)
                    Spacer()
                    Text("\(count)")
                        .font(FixoraFont.mono(12))
                        .foregroundColor(Color.textSecondary)
                }

                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.divider)
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(type.color)
                            .frame(width: max(g.size.width * fraction, 4), height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
    }
}

struct SafetyStatusBadge: View {
    let count: Int
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            Text("\(count)")
                .font(FixoraFont.heading(20))
                .foregroundColor(Color.textPrimary)
            Text(label)
                .font(FixoraFont.caption(10))
                .foregroundColor(Color.textInactive)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.2), lineWidth: 1))
    }
}

struct RecentRoomRow: View {
    let room: Room

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.accentPurple.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.accentPurpleSoft)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(room.name)
                    .font(FixoraFont.subheading(14))
                    .foregroundColor(Color.textPrimary)
                Text("\(room.cables.count) cables · \(String(format: "%.1f", room.width))×\(String(format: "%.1f", room.height))m")
                    .font(FixoraFont.caption(12))
                    .foregroundColor(Color.textInactive)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(Color.textInactive)
        }
    }
}
