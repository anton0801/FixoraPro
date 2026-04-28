import Foundation

final class DefaultModuleContainer: ModuleContainer {
    
    let crate: VersionedCrate
    let validation: ValidationStream
    let reacquisition: ReacquisitionWorker
    let delivery: DeliveryDiscoverer
    let approval: ApprovalGateway
    
    init() {
        self.crate = FixoraCrate()
        self.validation = SupabaseValidationStream()
        self.reacquisition = AppsFlyerReacquisition()
        self.delivery = HTTPDeliveryDiscoverer()
        self.approval = NotificationApproval()
    }
}
