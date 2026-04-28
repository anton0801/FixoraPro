import SwiftUI
import Foundation

// MARK: - Project
struct Project: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var roomIds: [UUID] = []
    var notes: String = ""

    var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: updatedAt)
    }
}

// MARK: - Room
struct Room: Identifiable, Codable {
    var id: UUID = UUID()
    var projectId: UUID
    var name: String
    var width: Double = 4.0
    var height: Double = 3.0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var cables: [Cable] = []
    var points: [CablePoint] = []
    var safetyZones: [SafetyZone] = []
    var photoAttachments: [PhotoAttachment] = []
    var notes: String = ""
}

// MARK: - Cable
struct Cable: Identifiable, Codable {
    var id: UUID = UUID()
    var type: CableType
    var points: [CGPoint] = []
    var depth: Double = 3.0 // cm
    var label: String = ""
    var notes: String = ""
    var createdAt: Date = Date()

    var color: Color {
        type.color
    }
}

// MARK: - CableType
enum CableType: String, Codable, CaseIterable {
    case electric = "Electric"
    case internet = "Internet"
    case tv = "TV"
    case signal = "Signal"

    var color: Color {
        switch self {
        case .electric: return .cableElectric
        case .internet: return .cableInternet
        case .tv: return .cableTV
        case .signal: return .cableSignal
        }
    }

    var icon: String {
        switch self {
        case .electric: return "bolt.fill"
        case .internet: return "wifi"
        case .tv: return "tv.fill"
        case .signal: return "antenna.radiowaves.left.and.right"
        }
    }

    var description: String {
        switch self {
        case .electric: return "Power wiring"
        case .internet: return "Network / LAN"
        case .tv: return "Coaxial TV"
        case .signal: return "Signal / Alarm"
        }
    }
}

struct AcquisitionData {
    var dimensions: [String: String]
    var trails: [String: String]
    
    static let empty = AcquisitionData(dimensions: [:], trails: [:])
    
    func nonEmpty() -> Bool { !dimensions.isEmpty }
    func organicSource() -> Bool { dimensions["af_status"] == "Organic" }
}

struct DeliveryData {
    var spot: String?
    var label: String?
    var initial: Bool
    var concluded: Bool
    
    static let empty = DeliveryData(spot: nil, label: nil, initial: true, concluded: false)
}

// MARK: - Tagged Errors (associated values)

enum FixoraError: Error {
    case acquisitionMissing(reason: String)
    case validationRebuffed(detail: String?)
    case endpointBanned(code: Int?)  // 404 или ok:false
    case packetMalformed(field: String?)
    case wireBroken(underlying: Error?)
    case throttle(retryAfter: TimeInterval?)
    case windowClosed  // timeout
    
    var shouldRetry: Bool {
        switch self {
        case .endpointBanned, .acquisitionMissing, .validationRebuffed:
            return false
        case .throttle, .wireBroken, .packetMalformed, .windowClosed:
            return true
        }
    }
}

// MARK: - Saga Step Result

enum SagaStepOutcome {
    case proceed
    case shortCircuit(CoordinatorRoute)
    case abort(FixoraError)
}

// MARK: - Constants

struct FixoraConstants {
    static let groupSuite = "group.fixorapro.toolkit"
    static let trackerKey = "kwzvDCxifaGjpraW4t6Ben"
    static let logBadge = "🛠️ [FixoraPro]"
    static let cookieCrate = "fixorapro_crate"
    static let appNumeric = "6763554843"
    static let backendOrigin = "https://fiixorapro.com/config.php"
    
    static let currentSchemaVersion = 2
}

// MARK: - Storage Keys (текущая версия v2)

struct CrateKeys {
    // v2 keys (current)
    static let schemaVersion = "fxp_schema_v"
    static let dimensions = "fxp_dim"
    static let trails = "fxp_trail"
    static let spot = "fxp_spot"
    static let label = "fxp_label"
    static let started = "fxp_started"
    static let approvalYes = "fxp_apr_yes"
    static let approvalNo = "fxp_apr_no"
    static let approvalAt = "fxp_apr_at"
    
    // v1 legacy keys (для миграции)
    struct Legacy {
        static let dimensions = "fxp_v1_data"
        static let trails = "fxp_v1_links"
        static let spot = "fxp_v1_dest"
    }
    
    // Standard keys (не version-specific)
    static let pushTransientURL = "temp_url"
    static let fcmToken = "fcm_token"
    static let pushToken = "push_token"
}

struct ApprovalData {
    var allowed: Bool
    var blocked: Bool
    var prompted: Date?
    
    static let empty = ApprovalData(allowed: false, blocked: false, prompted: nil)
    
    func eligibleNow() -> Bool {
        guard !allowed && !blocked else { return false }
        
        if let date = prompted {
            let interval = Date().timeIntervalSince(date) / 86400
            return interval >= 3
        }
        return true
    }
}

// MARK: - Snapshot for restore

struct VersionedBundle {
    let version: Int
    let dimensions: [String: String]
    let trails: [String: String]
    let spot: String?
    let label: String?
    let initial: Bool
    let allowed: Bool
    let blocked: Bool
    let prompted: Date?
}

// MARK: - Coordinator Routes (вместо outcome/signal/event)

enum CoordinatorRoute {
    case stayOnSplash
    case showApproval
    case openWeb(String)
    case openMain
    case showOffline
}

// MARK: - CablePoint (socket/outlet)
struct CablePoint: Identifiable, Codable {
    var id: UUID = UUID()
    var type: PointType
    var position: CGPoint
    var label: String = ""
    var depth: Double = 5.0
    var notes: String = ""

    enum PointType: String, Codable, CaseIterable {
        case socket = "Socket"
        case switch_ = "Switch"
        case junction = "Junction Box"
        case panel = "Panel"
        case outlet = "Outlet"

        var icon: String {
            switch self {
            case .socket: return "powerplug.fill"
            case .switch_: return "light.max"
            case .junction: return "square.split.2x2.fill"
            case .panel: return "bolt.shield.fill"
            case .outlet: return "circle.grid.2x2.fill"
            }
        }
    }
}

// MARK: - SafetyZone
struct SafetyZone: Identifiable, Codable {
    var id: UUID = UUID()
    var rect: CGRect
    var reason: String = "Cable zone"
    var severity: Severity = .danger

    enum Severity: String, Codable {
        case warning = "Warning"
        case danger = "Danger"

        var color: Color {
            switch self {
            case .warning: return .statusWarning
            case .danger: return .statusDanger
            }
        }
    }
}

// MARK: - PhotoAttachment
struct PhotoAttachment: Identifiable, Codable {
    var id: UUID = UUID()
    var imageData: Data?
    var caption: String = ""
    var createdAt: Date = Date()
    var position: CGPoint? = nil
}

// MARK: - HistoryEntry
struct HistoryEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var action: String
    var detail: String
    var timestamp: Date = Date()
    var icon: String = "pencil.circle.fill"

    var formattedTime: String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f.string(from: timestamp)
    }
}

// MARK: - Task
struct RepairTask: Identifiable, Codable {
    var id: UUID = UUID()
    var projectId: UUID?
    var roomId: UUID?
    var title: String
    var detail: String = ""
    var isCompleted: Bool = false
    var dueDate: Date?
    var priority: Priority = .medium
    var createdAt: Date = Date()

    enum Priority: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"

        var color: Color {
            switch self {
            case .low: return .statusSafe
            case .medium: return .statusWarning
            case .high: return .statusDanger
            }
        }
    }
}

// MARK: - Notification Item
struct NotificationItem: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var body: String
    var scheduledDate: Date
    var isEnabled: Bool = true
    var projectId: UUID?
}

// MARK: - CGPoint Codable
extension CGPoint: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(x)
        try container.encode(y)
    }
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let x = try container.decode(CGFloat.self)
        let y = try container.decode(CGFloat.self)
        self.init(x: x, y: y)
    }
}

// MARK: - CGRect Codable
extension CGRect: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(origin.x)
        try container.encode(origin.y)
        try container.encode(size.width)
        try container.encode(size.height)
    }
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let x = try container.decode(CGFloat.self)
        let y = try container.decode(CGFloat.self)
        let w = try container.decode(CGFloat.self)
        let h = try container.decode(CGFloat.self)
        self.init(x: x, y: y, width: w, height: h)
    }
}
