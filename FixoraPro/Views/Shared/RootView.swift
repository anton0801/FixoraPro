import SwiftUI

struct RootView: View {
    @StateObject private var appState = AppState()
    @StateObject private var projectsVM = ProjectsViewModel()
    @StateObject private var settingsVM = SettingsViewModel()

    var body: some View {
        ZStack {
            if !appState.hasCompletedOnboarding {
                OnboardingView()
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            } else if !appState.isLoggedIn {
                WelcomeView()
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            } else {
                MainTabView()
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appState.isLoggedIn)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appState.hasCompletedOnboarding)
        .environmentObject(appState)
        .environmentObject(projectsVM)
        .environmentObject(settingsVM)
        .preferredColorScheme(settingsVM.colorScheme)
    }
}
