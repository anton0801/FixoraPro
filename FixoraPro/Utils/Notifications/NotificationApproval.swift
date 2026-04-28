import Foundation
import UIKit
import UserNotifications
import Combine

final class NotificationApproval: ApprovalGateway {
    
    let approvalPublisher = PassthroughSubject<Bool, Never>()
    
    func ask() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.approvalPublisher.send(granted)
            }
        }
    }
    
    func arm() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}
