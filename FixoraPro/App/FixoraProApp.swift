import SwiftUI

@main
struct FixoraProApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var projectsVM = ProjectsViewModel()
    @StateObject private var settingsVM = SettingsViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(projectsVM)
                .environmentObject(settingsVM)
                .preferredColorScheme(settingsVM.colorScheme)
        }
    }
}
