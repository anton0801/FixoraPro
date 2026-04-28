import Foundation
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import WebKit

final class AppsFlyerReacquisition: ReacquisitionWorker {
    
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }
    
    func fetchAgain(deviceID: String) async throws -> [String: Any] {
        var components = URLComponents(string: "https://gcdsdk.appsflyer.com/install_data/v4.0/id\(FixoraConstants.appNumeric)")
        components?.queryItems = [
            URLQueryItem(name: "devkey", value: FixoraConstants.trackerKey),
            URLQueryItem(name: "device_id", value: deviceID)
        ]
        
        guard let requestURL = components?.url else {
            throw FixoraError.packetMalformed(field: "url")
        }
        
        var request = URLRequest(url: requestURL)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw FixoraError.wireBroken(underlying: nil)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw FixoraError.packetMalformed(field: "json")
        }
        
        return json
    }
}

final class HTTPDeliveryDiscoverer: DeliveryDiscoverer {
    
    private let session: URLSession
    private let backoffSchedule: [Double] = [44.0, 88.0, 176.0]
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }
    
    private var browserAgent: String = WKWebView().value(forKey: "userAgent") as? String ?? ""
    
    func discover(seed: [String: Any]) async throws -> String {
        guard let endpoint = URL(string: FixoraConstants.backendOrigin) else {
            throw FixoraError.packetMalformed(field: "endpoint")
        }
        
        var payload: [String: Any] = seed
        payload["os"] = "iOS"
        payload["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        payload["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        payload["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        payload["store_id"] = "id\(FixoraConstants.appNumeric)"
        payload["push_token"] = UserDefaults.standard.string(forKey: CrateKeys.pushToken)
            ?? Messaging.messaging().fcmToken
        payload["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(browserAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        var lastError: Error?
        
        for (idx, delay) in backoffSchedule.enumerated() {
            do {
                return try await singleAttempt(request)
            } catch let error as FixoraError {
                if !error.shouldRetry {
                    throw error
                }
                
                if case .throttle = error {
                    let waitTime = delay * Double(idx + 1)
                    try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                    continue
                }
                
                lastError = error
                if idx < backoffSchedule.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            } catch {
                lastError = FixoraError.wireBroken(underlying: error)
                if idx < backoffSchedule.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? FixoraError.wireBroken(underlying: nil)
    }
    
    private func singleAttempt(_ request: URLRequest) async throws -> String {
        let (data, response) = try await session.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw FixoraError.wireBroken(underlying: nil)
        }
        
        if http.statusCode == 404 {
            throw FixoraError.endpointBanned(code: 404)
        }
        
        if http.statusCode == 429 {
            throw FixoraError.throttle(retryAfter: nil)
        }
        
        guard (200...299).contains(http.statusCode) else {
            throw FixoraError.wireBroken(underlying: nil)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw FixoraError.packetMalformed(field: "json")
        }
        
        guard let ok = json["ok"] as? Bool else {
            throw FixoraError.packetMalformed(field: "ok")
        }
        
        if !ok {
            throw FixoraError.endpointBanned(code: nil)
        }
        
        guard let url = json["url"] as? String else {
            throw FixoraError.packetMalformed(field: "url")
        }
        
        return url
    }
}
