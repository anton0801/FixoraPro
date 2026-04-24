import SwiftUI
import UserNotifications

class SettingsViewModel: ObservableObject {
    @AppStorage("themeMode") var themeMode: String = "dark" {
        didSet { objectWillChange.send() }
    }
    @AppStorage("measurementUnit") var measurementUnit: String = "metric" {
        didSet { objectWillChange.send() }
    }
    @AppStorage("showGrid") var showGrid: Bool = true {
        didSet { objectWillChange.send() }
    }
    @AppStorage("gridSize") var gridSize: Double = 20.0 {
        didSet { objectWillChange.send() }
    }
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = false {
        didSet {
            if notificationsEnabled { requestNotificationPermission() }
        }
    }
    @AppStorage("snapToGrid") var snapToGrid: Bool = true
    @AppStorage("showDepthLabels") var showDepthLabels: Bool = true
    @AppStorage("defaultCableType") var defaultCableTypeRaw: String = "electric"
    @AppStorage("defaultDepth") var defaultDepth: Double = 3.0
    @AppStorage("exportFormat") var exportFormat: String = "PDF"

    var colorScheme: ColorScheme? {
        switch themeMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var defaultCableType: CableType {
        get { CableType(rawValue: defaultCableTypeRaw) ?? .electric }
        set { defaultCableTypeRaw = newValue.rawValue }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                if !granted {
                    self.notificationsEnabled = false
                }
            }
        }
    }
}
