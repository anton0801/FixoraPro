import Foundation
import Combine

protocol VersionedCrate {
    func writeAcquisition(_ data: [String: String])
    func writeDeeplinks(_ data: [String: String])
    func writeDelivery(spot: String, label: String)
    func writeApproval(_ approval: ApprovalData)
    func recordFirstRun()
    func unpackBundle() -> VersionedBundle
    func performMigrationIfNeeded()
}

protocol ValidationStream {
    func validationSequence() -> AsyncThrowingStream<Bool, Error>
}

protocol ReacquisitionWorker {
    func fetchAgain(deviceID: String) async throws -> [String: Any]
}

protocol DeliveryDiscoverer {
    func discover(seed: [String: Any]) async throws -> String
}

protocol ApprovalGateway {
    var approvalPublisher: PassthroughSubject<Bool, Never> { get }
    func ask()
    func arm()
}

protocol ModuleContainer {
    var crate: VersionedCrate { get }
    var validation: ValidationStream { get }
    var reacquisition: ReacquisitionWorker { get }
    var delivery: DeliveryDiscoverer { get }
    var approval: ApprovalGateway { get }
}

final class StateReference {
    
    var acquisition: AcquisitionData = .empty {
        willSet { stateWillChange?(.acquisition) }
        didSet { stateDidChange?(.acquisition) }
    }
    
    var delivery: DeliveryData = .empty {
        willSet { stateWillChange?(.delivery) }
        didSet { stateDidChange?(.delivery) }
    }
    
    var approval: ApprovalData = .empty {
        willSet { stateWillChange?(.approval) }
        didSet { stateDidChange?(.approval) }
    }
    
    var organicConsumed: Bool = false
    
    var stateWillChange: ((StateField) -> Void)?
    var stateDidChange: ((StateField) -> Void)?
    
    enum StateField {
        case acquisition, delivery, approval
    }
}
