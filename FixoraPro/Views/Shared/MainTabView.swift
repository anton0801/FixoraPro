import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var settingsVM: SettingsViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(0)

                ProjectsListView()
                    .tag(1)

                RoomsListView(projectId: nil)
                    .tag(2)

                TasksView()
                    .tag(3)

                SettingsView()
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)

            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int

    let tabs: [(icon: String, label: String)] = [
        ("square.grid.2x2.fill", "Home"),
        ("folder.fill", "Projects"),
        ("square.split.2x2.fill", "Rooms"),
        ("checkmark.circle.fill", "Tasks"),
        ("gearshape.fill", "Settings")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { i, tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = i
                    }
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if selectedTab == i {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.accentCyan.opacity(0.15))
                                    .frame(width: 44, height: 32)
                                    .cyanGlow(radius: 6)
                            }

                            Image(systemName: tab.icon)
                                .font(.system(size: selectedTab == i ? 20 : 18, weight: .semibold))
                                .foregroundColor(selectedTab == i ? Color.accentCyan : Color.textInactive)
                                .scaleEffect(selectedTab == i ? 1.1 : 1.0)
                        }

                        Text(tab.label)
                            .font(FixoraFont.caption(10))
                            .foregroundColor(selectedTab == i ? Color.accentCyan : Color.textInactive)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(IconButtonStyle())
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 28)
        .padding(.horizontal, 8)
        .background(
            Color.bgSoft
                .overlay(
                    Rectangle()
                        .fill(Color.divider.opacity(0.5))
                        .frame(height: 1),
                    alignment: .top
                )
        )
    }
}
