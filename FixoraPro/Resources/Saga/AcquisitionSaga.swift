import Foundation
import AppsFlyerLib
import Combine

final class AcquisitionSaga {
    
    private let modules: ModuleContainer
    private let state: StateReference
    
    private var sequenceCompleted: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private weak var approvalListener: AnyObject?
    
    init(modules: ModuleContainer, state: StateReference) {
        self.modules = modules
        self.state = state
    }
    
    func execute() async -> CoordinatorRoute? {
        guard !sequenceCompleted else { return nil }
        
        if let tempURL = UserDefaults.standard.string(forKey: CrateKeys.pushTransientURL),
           !tempURL.isEmpty {
            return finalizeDelivery(url: tempURL)
        }
        
        guard state.acquisition.nonEmpty() else {
            return nil
        }
        
        let validationOutcome = await stepValidate()
        switch validationOutcome {
        case .proceed:
            break
        case .shortCircuit(let route):
            return route
        case .abort(let error):
            return abortToFallback(error)
        }
        
        let organicOutcome = await stepMaybeOrganic()
        switch organicOutcome {
        case .proceed:
            break
        case .shortCircuit(let route):
            return route
        case .abort(let error):
            return abortToFallback(error)
        }
        
        let discoveryOutcome = await stepDiscoverDelivery()
        switch discoveryOutcome {
        case .proceed:
            return abortToFallback(.wireBroken(underlying: nil))
        case .shortCircuit(let route):
            return route
        case .abort(let error):
            return abortToFallback(error)
        }
    }
    
    func executeApprovalAccept() async -> CoordinatorRoute {
        var localApproval = state.approval
        
        let granted = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            var subscription: AnyCancellable?
            subscription = modules.approval.approvalPublisher
                .first()
                .sink { value in
                    subscription?.cancel()
                    continuation.resume(returning: value)
                }
            
            modules.approval.ask()
        }
        
        if granted {
            localApproval.allowed = true
            localApproval.blocked = false
            localApproval.prompted = Date()
            modules.approval.arm()
        } else {
            localApproval.allowed = false
            localApproval.blocked = true
            localApproval.prompted = Date()
        }
        
        state.approval = localApproval
        modules.crate.writeApproval(localApproval)
        
        if let spot = state.delivery.spot {
            return .openWeb(spot)
        }
        return .openMain
    }
    
    func executeApprovalDecline() -> CoordinatorRoute {
        state.approval.prompted = Date()
        modules.crate.writeApproval(state.approval)
        
        if let spot = state.delivery.spot {
            return .openWeb(spot)
        }
        return .openMain
    }
    
    func reportTimeoutOccurred() -> Bool {
        guard !sequenceCompleted else {
            return false
        }
        sequenceCompleted = true
        return true
    }
    
    private func stepValidate() async -> SagaStepOutcome {
        do {
            let stream = modules.validation.validationSequence()
            
            for try await isValid in stream {
                if isValid {
                    return .proceed
                } else {
                    return .shortCircuit(.openMain)
                }
            }
            
            return .shortCircuit(.openMain)
        } catch let error as FixoraError {
            return .abort(error)
        } catch {
            return .abort(.validationRebuffed(detail: error.localizedDescription))
        }
    }
    
    private func stepMaybeOrganic() async -> SagaStepOutcome {
        guard state.acquisition.organicSource(),
              state.delivery.initial,
              !state.organicConsumed else {
            return .proceed
        }
        
        state.organicConsumed = true
        
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        guard !state.delivery.concluded else {
            return .proceed  // продолжаем дальше
        }
        
        let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
        
        do {
            var fetched = try await modules.reacquisition.fetchAgain(deviceID: deviceID)
            
            for (k, v) in state.acquisition.trails {
                if fetched[k] == nil {
                    fetched[k] = v
                }
            }
            
            let mapped = fetched.mapValues { "\($0)" }
            state.acquisition.dimensions = mapped
            modules.crate.writeAcquisition(mapped)
        } catch {
        }
        
        return .proceed
    }
    
    /// Шаг 3: discover delivery URL
    private func stepDiscoverDelivery() async -> SagaStepOutcome {
        let seed = state.acquisition.dimensions.mapValues { $0 as Any }
        
        do {
            let url = try await modules.delivery.discover(seed: seed)
            let route = finalizeDelivery(url: url)
            return .shortCircuit(route)
        } catch let error as FixoraError {
            return .abort(error)
        } catch {
            return .abort(.wireBroken(underlying: error))
        }
    }
    
    private func finalizeDelivery(url: String) -> CoordinatorRoute {
        let needsApproval = state.approval.eligibleNow()
        
        state.delivery.spot = url
        state.delivery.label = "Active"
        state.delivery.initial = false
        state.delivery.concluded = true
        
        modules.crate.writeDelivery(spot: url, label: "Active")
        modules.crate.recordFirstRun()
        
        UserDefaults.standard.removeObject(forKey: CrateKeys.pushTransientURL)
        
        sequenceCompleted = true
        
        return needsApproval ? .showApproval : .openWeb(url)
    }
    
    private func abortToFallback(_ error: FixoraError) -> CoordinatorRoute {
        sequenceCompleted = true
        return .openMain
    }
}

@MainActor
final class FixoraCoordinator {
    
    var onRouteToMain: (() -> Void)?
    var onRouteToWeb: ((String) -> Void)?
    var onRouteToApproval: (() -> Void)?
    var onRouteToOffline: (() -> Void)?
    var onRouteToOnline: (() -> Void)?
    
    func apply(_ route: CoordinatorRoute) {
        switch route {
        case .stayOnSplash:
            break  // ничего не делаем
        case .openMain:
            onRouteToMain?()
        case .openWeb(let url):
            onRouteToWeb?(url)
        case .showApproval:
            onRouteToApproval?()
        case .showOffline:
            onRouteToOffline?()
        }
    }
    
    func networkChanged(connected: Bool) {
        if connected {
            onRouteToOnline?()
        } else {
            onRouteToOffline?()
        }
    }
}
