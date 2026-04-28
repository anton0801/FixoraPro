import UIKit
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AppsFlyerLib


final class AppsFlyerDelegateUnit: NSObject {
    
    private weak var pipeline: DataPipelineUnit?
    
    init(pipeline: DataPipelineUnit) {
        self.pipeline = pipeline
    }
    
    func configure(delegate: AppDelegate) {
        let sdk = AppsFlyerLib.shared()
        sdk.appsFlyerDevKey = FixoraConstants.trackerKey
        sdk.appleAppID = FixoraConstants.appNumeric
        sdk.delegate = delegate
        sdk.deepLinkDelegate = delegate
        sdk.isDebug = false
    }
    
    func startTracking() {
        if #available(iOS 14, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                    UserDefaults.standard.set(status.rawValue, forKey: "att_status")
                }
            }
        } else {
            AppsFlyerLib.shared().start()
        }
    }
    
    func handleConversionSuccess(_ data: [AnyHashable: Any]) {
        pipeline?.acceptAttribution(data)
    }
    
    func handleConversionFailure(_ error: Error) {
        let errorData: [AnyHashable: Any] = [
            "error": true,
            "error_desc": error.localizedDescription
        ]
        pipeline?.acceptAttribution(errorData)
    }
    
    func handleDeeplink(_ result: DeepLinkResult) {
        guard case .found = result.status,
              let link = result.deepLink else { return }
        
        pipeline?.acceptDeeplinks(link.clickEvent)
    }
}


final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private let firebaseUnit = FirebaseDelegateUnit()
    private lazy var dataPipeline: DataPipelineUnit = {
        let unit = DataPipelineUnit()
        unit.attributionForwarder = { [weak self] data in
            self?.broadcastAttribution(data)
        }
        unit.deeplinksForwarder = { [weak self] data in
            self?.broadcastDeeplinks(data)
        }
        return unit
    }()
    private lazy var appsFlyerUnit = AppsFlyerDelegateUnit(pipeline: dataPipeline)
    private let pushUnit = PushDelegateUnit()
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        firebaseUnit.boot()
        firebaseUnit.attachMessagingDelegate(self)
        firebaseUnit.attachNotificationDelegate(self)
        
        appsFlyerUnit.configure(delegate: self)
        
        if let remote = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            pushUnit.handle(remote)
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onActivation),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    @objc private func onActivation() {
        appsFlyerUnit.startTracking()
    }
    
    private func broadcastAttribution(_ data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: .init("ConversionDataReceived"),
            object: nil,
            userInfo: ["conversionData": data]
        )
    }
    
    private func broadcastDeeplinks(_ data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: .init("deeplink_values"),
            object: nil,
            userInfo: ["deeplinksData": data]
        )
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        firebaseUnit.persistFCMToken(messaging: messaging)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        pushUnit.handle(notification.request.content.userInfo)
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        pushUnit.handle(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        pushUnit.handle(userInfo)
        completionHandler(.newData)
    }
}

extension AppDelegate: AppsFlyerLibDelegate, DeepLinkDelegate {
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        appsFlyerUnit.handleConversionSuccess(data)
    }
    
    func onConversionDataFail(_ error: Error) {
        appsFlyerUnit.handleConversionFailure(error)
    }
    
    func didResolveDeepLink(_ result: DeepLinkResult) {
        appsFlyerUnit.handleDeeplink(result)
    }
}

final class FirebaseDelegateUnit: NSObject {
    
    func boot() {
        FirebaseApp.configure()
    }
    
    func attachMessagingDelegate(_ delegate: MessagingDelegate) {
        Messaging.messaging().delegate = delegate
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func attachNotificationDelegate(_ delegate: UNUserNotificationCenterDelegate) {
        UNUserNotificationCenter.current().delegate = delegate
    }
    
    func persistFCMToken(messaging: Messaging) {
        messaging.token { token, err in
            guard err == nil, let t = token else { return }
            
            UserDefaults.standard.set(t, forKey: CrateKeys.fcmToken)
            UserDefaults.standard.set(t, forKey: CrateKeys.pushToken)
            UserDefaults(suiteName: FixoraConstants.groupSuite)?.set(t, forKey: "shared_fcm")
        }
    }
}

final class PushDelegateUnit: NSObject {
    
    func handle(_ payload: [AnyHashable: Any]) {
        guard let url = scanForURL(payload) else { return }
        
        UserDefaults.standard.set(url, forKey: CrateKeys.pushTransientURL)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            NotificationCenter.default.post(
                name: .init("LoadTempURL"),
                object: nil,
                userInfo: ["temp_url": url]
            )
        }
    }
    
    private func scanForURL(_ payload: [AnyHashable: Any]) -> String? {
        if let direct = payload["url"] as? String {
            return direct
        }
        
        if let nested = payload["data"] as? [String: Any],
           let url = nested["url"] as? String {
            return url
        }
        
        if let aps = payload["aps"] as? [String: Any],
           let nested = aps["data"] as? [String: Any],
           let url = nested["url"] as? String {
            return url
        }
        
        if let custom = payload["custom"] as? [String: Any],
           let url = custom["target_url"] as? String {
            return url
        }
        
        return nil
    }
}

final class DataPipelineUnit: NSObject {
    
    var attributionForwarder: (([AnyHashable: Any]) -> Void)?
    var deeplinksForwarder: (([AnyHashable: Any]) -> Void)?
    
    private var attributionBuffer: [AnyHashable: Any] = [:]
    private var deeplinksBuffer: [AnyHashable: Any] = [:]
    private var fuseTimer: Timer?
    
    func acceptAttribution(_ data: [AnyHashable: Any]) {
        attributionBuffer = data
        scheduleFuse()
        
        if !deeplinksBuffer.isEmpty {
            performFuse()
        }
    }
    
    func acceptDeeplinks(_ data: [AnyHashable: Any]) {
        guard !UserDefaults.standard.bool(forKey: CrateKeys.started) else { return }
        
        deeplinksBuffer = data
        deeplinksForwarder?(data)
        fuseTimer?.invalidate()
        
        if !attributionBuffer.isEmpty {
            performFuse()
        }
    }
    
    private func scheduleFuse() {
        fuseTimer?.invalidate()
        fuseTimer = Timer.scheduledTimer(
            withTimeInterval: 2.5,
            repeats: false
        ) { [weak self] _ in
            self?.performFuse()
        }
    }
    
    private func performFuse() {
        var fused = attributionBuffer
        
        for (k, v) in deeplinksBuffer {
            let prefixed = "deep_\(k)"
            if fused[prefixed] == nil {
                fused[prefixed] = v
            }
        }
        
        attributionForwarder?(fused)
    }
}
