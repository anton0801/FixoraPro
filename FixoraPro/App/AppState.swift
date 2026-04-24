import SwiftUI
import Combine

class AppState: ObservableObject {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("currentUserName") var currentUserName: String = ""
    @AppStorage("currentUserEmail") var currentUserEmail: String = ""
    @AppStorage("isDemoAccount") var isDemoAccount: Bool = false

    @Published var showSplash: Bool = true

    func loginDemo() {
        currentUserName = "Demo User"
        currentUserEmail = "demo@fixorapro.app"
        isDemoAccount = true
        isLoggedIn = true
    }

    func login(name: String, email: String) {
        currentUserName = name
        currentUserEmail = email
        isDemoAccount = false
        isLoggedIn = true
    }

    func logout() {
        isLoggedIn = false
        currentUserName = ""
        currentUserEmail = ""
        isDemoAccount = false
    }

    func deleteAccount() {
        logout()
        hasCompletedOnboarding = false
        UserDefaults.standard.removeObject(forKey: "projects_data")
        UserDefaults.standard.removeObject(forKey: "rooms_data")
    }
}
