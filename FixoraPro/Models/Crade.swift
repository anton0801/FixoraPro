import Foundation

final class FixoraCrate: VersionedCrate {
    
    private let groupDefaults: UserDefaults
    private let standardDefaults: UserDefaults
    
    init() {
        self.groupDefaults = UserDefaults(suiteName: FixoraConstants.groupSuite)!
        self.standardDefaults = UserDefaults.standard
        
        performMigrationIfNeeded()
    }
    
    func performMigrationIfNeeded() {
        let storedVersion = groupDefaults.integer(forKey: CrateKeys.schemaVersion)
        
        if storedVersion < FixoraConstants.currentSchemaVersion {
            if storedVersion < 1 {
                migrateLegacyV0ToV1()
            }
            if storedVersion < 2 {
                migrateV1ToV2()
            }
            
            groupDefaults.set(FixoraConstants.currentSchemaVersion, forKey: CrateKeys.schemaVersion)
        }
    }
    
    private func migrateLegacyV0ToV1() {
        // Демо-миграция: переносим из старых ключей в новые
        if let legacyDim = groupDefaults.string(forKey: CrateKeys.Legacy.dimensions) {
            groupDefaults.set(legacyDim, forKey: CrateKeys.dimensions)
            groupDefaults.removeObject(forKey: CrateKeys.Legacy.dimensions)
        }
        
        if let legacyTrails = groupDefaults.string(forKey: CrateKeys.Legacy.trails) {
            groupDefaults.set(legacyTrails, forKey: CrateKeys.trails)
            groupDefaults.removeObject(forKey: CrateKeys.Legacy.trails)
        }
        
        if let legacySpot = groupDefaults.string(forKey: CrateKeys.Legacy.spot) {
            groupDefaults.set(legacySpot, forKey: CrateKeys.spot)
            groupDefaults.removeObject(forKey: CrateKeys.Legacy.spot)
        }
    }
    
    private func migrateV1ToV2() {
    }
    
    func writeAcquisition(_ data: [String: String]) {
        guard let serialized = serialize(data) else { return }
        groupDefaults.set(serialized, forKey: CrateKeys.dimensions)
    }
    
    func writeDeeplinks(_ data: [String: String]) {
        guard let serialized = serialize(data) else { return }
        let scrambled = scramble(serialized)
        groupDefaults.set(scrambled, forKey: CrateKeys.trails)
    }
    
    func writeDelivery(spot: String, label: String) {
        groupDefaults.set(spot, forKey: CrateKeys.spot)
        standardDefaults.set(spot, forKey: CrateKeys.spot)
        groupDefaults.set(label, forKey: CrateKeys.label)
    }
    
    func writeApproval(_ approval: ApprovalData) {
        groupDefaults.set(approval.allowed, forKey: CrateKeys.approvalYes)
        groupDefaults.set(approval.blocked, forKey: CrateKeys.approvalNo)
        
        if let when = approval.prompted {
            let ms = when.timeIntervalSince1970 * 1000
            groupDefaults.set(ms, forKey: CrateKeys.approvalAt)
        }
    }
    
    func recordFirstRun() {
        groupDefaults.set(true, forKey: CrateKeys.started)
    }
    
    func unpackBundle() -> VersionedBundle {
        let version = groupDefaults.integer(forKey: CrateKeys.schemaVersion)
        
        let dimSerialized = groupDefaults.string(forKey: CrateKeys.dimensions) ?? ""
        let dimensions = deserialize(dimSerialized) ?? [:]
        
        let trailsScrambled = groupDefaults.string(forKey: CrateKeys.trails) ?? ""
        let trailsSerialized = unscramble(trailsScrambled) ?? ""
        let trails = deserialize(trailsSerialized) ?? [:]
        
        let spot = groupDefaults.string(forKey: CrateKeys.spot)
        let label = groupDefaults.string(forKey: CrateKeys.label)
        let started = groupDefaults.bool(forKey: CrateKeys.started)
        
        let allowed = groupDefaults.bool(forKey: CrateKeys.approvalYes)
        let blocked = groupDefaults.bool(forKey: CrateKeys.approvalNo)
        let promptedMs = groupDefaults.double(forKey: CrateKeys.approvalAt)
        let prompted = promptedMs > 0 ? Date(timeIntervalSince1970: promptedMs / 1000) : nil
        
        return VersionedBundle(
            version: version,
            dimensions: dimensions,
            trails: trails,
            spot: spot,
            label: label,
            initial: !started,
            allowed: allowed,
            blocked: blocked,
            prompted: prompted
        )
    }
    
    private func serialize(_ dict: [String: String]) -> String? {
        let anyDict = dict.mapValues { $0 as Any }
        guard let data = try? JSONSerialization.data(withJSONObject: anyDict),
              let text = String(data: data, encoding: .utf8) else {
            return nil
        }
        return text
    }
    
    private func deserialize(_ text: String) -> [String: String]? {
        guard let data = text.data(using: .utf8),
              let anyDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return anyDict.mapValues { "\($0)" }
    }
    
    private func scramble(_ input: String) -> String {
        let b64 = Data(input.utf8).base64EncodedString()
        return b64
            .replacingOccurrences(of: "=", with: "@")
            .replacingOccurrences(of: "+", with: ";")
    }
    
    private func unscramble(_ input: String) -> String? {
        let b64 = input
            .replacingOccurrences(of: "@", with: "=")
            .replacingOccurrences(of: ";", with: "+")
        
        guard let data = Data(base64Encoded: b64),
              let text = String(data: data, encoding: .utf8) else {
            return nil
        }
        return text
    }
}
