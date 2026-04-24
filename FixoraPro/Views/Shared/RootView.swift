import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settingsVM: SettingsViewModel
    @State private var splashDone = false

    var body: some View {
        ZStack {
            if !splashDone {
                SplashView(onComplete: { splashDone = true })
                    .transition(.opacity)
            } else if !appState.hasCompletedOnboarding {
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
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: splashDone)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appState.isLoggedIn)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appState.hasCompletedOnboarding)
    }
}
