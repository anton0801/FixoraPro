import SwiftUI
import Combine

class ProjectsViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var rooms: [Room] = []
    @Published var tasks: [RepairTask] = []
    @Published var history: [HistoryEntry] = []
    @Published var notifications: [NotificationItem] = []

    private let projectsKey = "projects_data"
    private let roomsKey = "rooms_data"
    private let tasksKey = "tasks_data"
    private let historyKey = "history_data"
    private let notificationsKey = "notifications_data"

    init() {
        load()
        if projects.isEmpty {
            seedDemoData()
        }
    }

    // MARK: - Projects CRUD
    func addProject(name: String) {
        let p = Project(name: name)
        projects.insert(p, at: 0)
        save()
        addHistory("Project created", detail: name, icon: "folder.fill.badge.plus")
    }

    func updateProject(_ project: Project) {
        if let idx = projects.firstIndex(where: { $0.id == project.id }) {
            var updated = project
            updated.updatedAt = Date()
            projects[idx] = updated
            save()
            addHistory("Project updated", detail: project.name, icon: "pencil.circle.fill")
        }
    }

    func deleteProject(_ project: Project) {
        rooms.removeAll { $0.projectId == project.id }
        projects.removeAll { $0.id == project.id }
        save()
        addHistory("Project deleted", detail: project.name, icon: "trash.fill")
    }

    // MARK: - Rooms CRUD
    func addRoom(name: String, width: Double, height: Double, projectId: UUID) {
        var r = Room(projectId: projectId, name: name, width: width, height: height)
        rooms.insert(r, at: 0)
        if let idx = projects.firstIndex(where: { $0.id == projectId }) {
            projects[idx].roomIds.append(r.id)
            projects[idx].updatedAt = Date()
        }
        save()
        addHistory("Room added", detail: name, icon: "square.grid.2x2.fill")
    }

    func updateRoom(_ room: Room) {
        if let idx = rooms.firstIndex(where: { $0.id == room.id }) {
            var updated = room
            updated.updatedAt = Date()
            rooms[idx] = updated
            save()
            addHistory("Room updated", detail: room.name, icon: "pencil.circle.fill")
        }
    }

    func deleteRoom(_ room: Room) {
        if let idx = projects.firstIndex(where: { $0.id == room.projectId }) {
            projects[idx].roomIds.removeAll { $0 == room.id }
        }
        rooms.removeAll { $0.id == room.id }
        save()
        addHistory("Room deleted", detail: room.name, icon: "trash.fill")
    }

    func rooms(for projectId: UUID) -> [Room] {
        rooms.filter { $0.projectId == projectId }
    }

    // MARK: - Cables
    func addCable(_ cable: Cable, to roomId: UUID) {
        if let idx = rooms.firstIndex(where: { $0.id == roomId }) {
            rooms[idx].cables.append(cable)
            rooms[idx].updatedAt = Date()
            save()
            addHistory("Cable added", detail: cable.type.rawValue, icon: "bolt.fill")
        }
    }

    func updateCable(_ cable: Cable, in roomId: UUID) {
        if let roomIdx = rooms.firstIndex(where: { $0.id == roomId }),
           let cIdx = rooms[roomIdx].cables.firstIndex(where: { $0.id == cable.id }) {
            rooms[roomIdx].cables[cIdx] = cable
            rooms[roomIdx].updatedAt = Date()
            save()
        }
    }

    func deleteCable(_ cable: Cable, from roomId: UUID) {
        if let idx = rooms.firstIndex(where: { $0.id == roomId }) {
            rooms[idx].cables.removeAll { $0.id == cable.id }
            rooms[idx].updatedAt = Date()
            save()
            addHistory("Cable removed", detail: cable.type.rawValue, icon: "trash.fill")
        }
    }

    // MARK: - Cable Points
    func addPoint(_ point: CablePoint, to roomId: UUID) {
        if let idx = rooms.firstIndex(where: { $0.id == roomId }) {
            rooms[idx].points.append(point)
            rooms[idx].updatedAt = Date()
            save()
            addHistory("Point added", detail: point.type.rawValue, icon: "plus.circle.fill")
        }
    }

    func deletePoint(_ point: CablePoint, from roomId: UUID) {
        if let idx = rooms.firstIndex(where: { $0.id == roomId }) {
            rooms[idx].points.removeAll { $0.id == point.id }
            rooms[idx].updatedAt = Date()
            save()
        }
    }

    // MARK: - Safety Zones
    func addSafetyZone(_ zone: SafetyZone, to roomId: UUID) {
        if let idx = rooms.firstIndex(where: { $0.id == roomId }) {
            rooms[idx].safetyZones.append(zone)
            rooms[idx].updatedAt = Date()
            save()
            addHistory("Safety zone added", detail: zone.reason, icon: "exclamationmark.triangle.fill")
        }
    }

    func deleteSafetyZone(_ zone: SafetyZone, from roomId: UUID) {
        if let idx = rooms.firstIndex(where: { $0.id == roomId }) {
            rooms[idx].safetyZones.removeAll { $0.id == zone.id }
            save()
        }
    }

    // MARK: - Photos
    func addPhoto(_ photo: PhotoAttachment, to roomId: UUID) {
        if let idx = rooms.firstIndex(where: { $0.id == roomId }) {
            rooms[idx].photoAttachments.append(photo)
            rooms[idx].updatedAt = Date()
            save()
            addHistory("Photo attached", detail: photo.caption.isEmpty ? "Photo" : photo.caption, icon: "camera.fill")
        }
    }

    func deletePhoto(_ photo: PhotoAttachment, from roomId: UUID) {
        if let idx = rooms.firstIndex(where: { $0.id == roomId }) {
            rooms[idx].photoAttachments.removeAll { $0.id == photo.id }
            save()
        }
    }

    // MARK: - Notes
    func updateNotes(_ notes: String, roomId: UUID) {
        if let idx = rooms.firstIndex(where: { $0.id == roomId }) {
            rooms[idx].notes = notes
            rooms[idx].updatedAt = Date()
            save()
        }
    }

    // MARK: - Tasks
    func addTask(title: String, detail: String, priority: RepairTask.Priority, dueDate: Date?, projectId: UUID?) {
        let t = RepairTask(projectId: projectId, title: title, detail: detail, dueDate: dueDate, priority: priority)
        tasks.insert(t, at: 0)
        save()
        addHistory("Task created", detail: title, icon: "checkmark.circle.fill")
    }

    func toggleTask(_ task: RepairTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx].isCompleted.toggle()
            save()
        }
    }

    func deleteTask(_ task: RepairTask) {
        tasks.removeAll { $0.id == task.id }
        save()
    }

    // MARK: - Notifications
    func addNotification(title: String, body: String, date: Date, projectId: UUID?) {
        let n = NotificationItem(title: title, body: body, scheduledDate: date, projectId: projectId)
        notifications.append(n)
        save()
        scheduleNotification(n)
    }

    func deleteNotification(_ item: NotificationItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [item.id.uuidString])
        notifications.removeAll { $0.id == item.id }
        save()
    }

    func toggleNotification(_ item: NotificationItem) {
        if let idx = notifications.firstIndex(where: { $0.id == item.id }) {
            notifications[idx].isEnabled.toggle()
            if notifications[idx].isEnabled {
                scheduleNotification(notifications[idx])
            } else {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [item.id.uuidString])
            }
            save()
        }
    }

    private func scheduleNotification(_ item: NotificationItem) {
        let content = UNMutableNotificationContent()
        content.title = item.title
        content.body = item.body
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: item.scheduledDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: item.id.uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { _ in }
    }

    // MARK: - History
    func addHistory(_ action: String, detail: String, icon: String = "pencil.circle.fill") {
        let entry = HistoryEntry(action: action, detail: detail, icon: icon)
        history.insert(entry, at: 0)
        if history.count > 100 { history = Array(history.prefix(100)) }
        saveHistory()
    }

    // MARK: - Stats
    var totalCables: Int {
        rooms.reduce(0) { $0 + $1.cables.count }
    }

    var totalPoints: Int {
        rooms.reduce(0) { $0 + $1.points.count }
    }

    var recentRooms: [Room] {
        Array(rooms.sorted { $0.updatedAt > $1.updatedAt }.prefix(5))
    }

    var cableCountByType: [(CableType, Int)] {
        CableType.allCases.map { type in
            let count = rooms.flatMap { $0.cables }.filter { $0.type == type }.count
            return (type, count)
        }
    }

    // MARK: - Persistence
    func save() {
        if let data = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(data, forKey: projectsKey)
        }
        if let data = try? JSONEncoder().encode(rooms) {
            UserDefaults.standard.set(data, forKey: roomsKey)
        }
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: tasksKey)
        }
        if let data = try? JSONEncoder().encode(notifications) {
            UserDefaults.standard.set(data, forKey: notificationsKey)
        }
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: projectsKey),
           let decoded = try? JSONDecoder().decode([Project].self, from: data) {
            projects = decoded
        }
        if let data = UserDefaults.standard.data(forKey: roomsKey),
           let decoded = try? JSONDecoder().decode([Room].self, from: data) {
            rooms = decoded
        }
        if let data = UserDefaults.standard.data(forKey: tasksKey),
           let decoded = try? JSONDecoder().decode([RepairTask].self, from: data) {
            tasks = decoded
        }
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data) {
            history = decoded
        }
        if let data = UserDefaults.standard.data(forKey: notificationsKey),
           let decoded = try? JSONDecoder().decode([NotificationItem].self, from: data) {
            notifications = decoded
        }
    }

    private func seedDemoData() {
        let proj = Project(name: "My Apartment")
        projects = [proj]

        var living = Room(projectId: proj.id, name: "Living Room", width: 5.5, height: 4.2)
        living.cables = [
            Cable(type: .electric, points: [CGPoint(x: 50, y: 50), CGPoint(x: 200, y: 50), CGPoint(x: 200, y: 150)], depth: 3.0, label: "Main power"),
            Cable(type: .internet, points: [CGPoint(x: 50, y: 200), CGPoint(x: 300, y: 200)], depth: 2.5, label: "LAN line")
        ]
        living.points = [
            CablePoint(type: .socket, position: CGPoint(x: 200, y: 150), label: "TV socket"),
            CablePoint(type: .switch_, position: CGPoint(x: 50, y: 100), label: "Light switch")
        ]

        var bedroom = Room(projectId: proj.id, name: "Bedroom", width: 3.8, height: 3.5)
        bedroom.cables = [
            Cable(type: .electric, points: [CGPoint(x: 30, y: 80), CGPoint(x: 180, y: 80)], depth: 3.0, label: "Bedroom power"),
            Cable(type: .tv, points: [CGPoint(x: 30, y: 160), CGPoint(x: 200, y: 160), CGPoint(x: 200, y: 80)], depth: 4.0, label: "TV coaxial")
        ]

        rooms = [living, bedroom]

        tasks = [
            RepairTask(projectId: proj.id, title: "Check junction box in kitchen", detail: "Possible loose wiring", isCompleted: false, priority: .high),
            RepairTask(projectId: proj.id, title: "Label all bedroom sockets", priority: .medium),
            RepairTask(projectId: proj.id, title: "Add internet cable in bathroom", priority: .low)
        ]

        history = [
            HistoryEntry(action: "Project created", detail: "My Apartment", icon: "folder.fill.badge.plus"),
            HistoryEntry(action: "Room added", detail: "Living Room", icon: "square.grid.2x2.fill"),
            HistoryEntry(action: "Cable mapped", detail: "Electric - Main power", icon: "bolt.fill")
        ]

        save()
        saveHistory()
    }
}

@MainActor
final class FixoraProViewModel: ObservableObject {
    
    @Published var navigateToMain = false {
        didSet {
            if navigateToMain {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }
    
    @Published var navigateToWeb = false {
        didSet {
            if navigateToWeb {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }
    
    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false
    
    private let modules: ModuleContainer
    private let state: StateReference
    private let saga: AcquisitionSaga
    private let coordinator: FixoraCoordinator
    
    private var deadlineTask: Task<Void, Never>?
    
    private var uiLocked: Bool = false
    
    init() {
        let container = DefaultModuleContainer()
        let state = StateReference()
        
        self.modules = container
        self.state = state
        self.saga = AcquisitionSaga(modules: container, state: state)
        self.coordinator = FixoraCoordinator()
        
        wireUpCoordinator()
    }
    
    private func wireUpCoordinator() {
        coordinator.onRouteToMain = { [weak self] in
            self?.applyRouteToMain()
        }
        coordinator.onRouteToWeb = { [weak self] _ in
            self?.applyRouteToWeb()
        }
        coordinator.onRouteToApproval = { [weak self] in
            self?.applyRouteToApproval()
        }
        coordinator.onRouteToOffline = { [weak self] in
            self?.showOfflineView = true
        }
        coordinator.onRouteToOnline = { [weak self] in
            self?.showOfflineView = false
        }
    }
    
    func boot() {
        Task {
            let bundle = modules.crate.unpackBundle()
            
            state.acquisition.dimensions = bundle.dimensions
            state.acquisition.trails = bundle.trails
            state.delivery.spot = bundle.spot
            state.delivery.label = bundle.label
            state.delivery.initial = bundle.initial
            state.approval.allowed = bundle.allowed
            state.approval.blocked = bundle.blocked
            state.approval.prompted = bundle.prompted
            
            armDeadline()
        }
    }
    
    func ingestAcquisition(_ data: [String: Any]) {
        Task {
            let mapped = data.mapValues { "\($0)" }
            state.acquisition.dimensions = mapped
            modules.crate.writeAcquisition(mapped)
            
            let route = await saga.execute()
            if let route = route {
                coordinator.apply(route)
            }
        }
    }
    
    func ingestDeeplinks(_ data: [String: Any]) {
        Task {
            let mapped = data.mapValues { "\($0)" }
            state.acquisition.trails = mapped
            modules.crate.writeDeeplinks(mapped)
        }
    }
    
    func acceptApproval() {
        Task {
            let route = await saga.executeApprovalAccept()
            showPermissionPrompt = false
            coordinator.apply(route)
        }
    }
    
    func declineApproval() {
        let route = saga.executeApprovalDecline()
        showPermissionPrompt = false
        coordinator.apply(route)
    }
    
    func networkConnectivityChanged(_ connected: Bool) {
        coordinator.networkChanged(connected: connected)
    }
    
    private func applyRouteToMain() {
        guard !uiLocked else {
            return
        }
        navigateToMain = true
    }
    
    private func applyRouteToWeb() {
        guard !uiLocked else {
            return
        }
        navigateToWeb = true
    }
    
    private func applyRouteToApproval() {
        guard !uiLocked else {
            return
        }
        showPermissionPrompt = true
    }
    
    private func armDeadline() {
        deadlineTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            
            guard let self = self else { return }
            
            let shouldFire = self.saga.reportTimeoutOccurred()
            if shouldFire {
                self.coordinator.apply(.openMain)
            }
        }
    }
    
    deinit {
        deadlineTask?.cancel()
    }
}
