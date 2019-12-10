//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Foundation
import WireDataModel
import LocalAuthentication

private let zmLog = ZMSLog(tag: "UI")

final public class AppLock {
    // Returns true if user enabled the app lock feature.
    
    public static var rules = AppLockRules.fromBundle()

    public static var isActive: Bool {
        get {
            guard !rules.forceAppLock else { return true }
            guard let data = ZMKeychain.data(forAccount: SettingsPropertyName.lockApp.rawValue),
                data.count != 0 else {
                    return false
            }
            
            return String(data: data, encoding: .utf8) == "YES"
        }
        set {
            guard !rules.forceAppLock else { return }
            let data = (newValue ? "YES" : "NO").data(using: .utf8)!
            ZMKeychain.setData(data, forAccount: SettingsPropertyName.lockApp.rawValue)
        }
    }
    
    // Returns the time since last lock happened.
    public static var lastUnlockedDate: Date = Date(timeIntervalSince1970: 0)
    
    public enum AuthenticationResult {
        /// User sucessfully authenticated
        case granted
        /// User failed to authenticate or cancelled the request
        case denied
        /// There's no authenticated method available (no passcode is set)
        case unavailable
        /// Biometrics failed and account password is needed instead of device PIN
        case needAccountPassword
    }

    /// a weak reference to LAContext, it should be nil when evaluatePolicy is done.
    private static weak var weakLAContext: LAContext? = nil

    // TODO: Persist domain state
    private static var previousDomainState: Data? = nil
    
    // Creates a new LAContext and evaluates the authentication settings of the user.
    public static func evaluateAuthentication(description: String, with callback: @escaping (AuthenticationResult) -> Void) {

        let useBiometricsOrAccountPassword = rules.useBiometricsOrAccountPassword
        let context: LAContext = LAContext()
        var error: NSError?

        AppLock.weakLAContext = context
        
        let policy: LAPolicy = useBiometricsOrAccountPassword ? LAPolicy.deviceOwnerAuthenticationWithBiometrics : LAPolicy.deviceOwnerAuthentication
        let canEvaluatePolicy = context.canEvaluatePolicy(policy, error: &error)
        
        if useBiometricsOrAccountPassword && (biometricsChanged(in: context) || !canEvaluatePolicy) {
            callback(.needAccountPassword)
            return
        }
        
        if canEvaluatePolicy {
            context.evaluatePolicy(policy, localizedReason: description, reply: { (success, error) -> Void in
                var authResult: AuthenticationResult = success ? .granted : .denied
            
                if useBiometricsOrAccountPassword, let laError = error as? LAError, laError.code == .userFallback {
                    authResult = .needAccountPassword
                }
                
                callback(authResult)
            })
        } else {
            // If there's no passcode set automatically grant access unless app lock is a requirement to run the app
            callback(rules.forceAppLock ? .unavailable : .granted)
            zmLog.error("Local authentication error: \(String(describing: error?.localizedDescription))")
        }
    }
    
    // Tells us if biometrics database has changed (ex: fingerprints added or removed)
    private static func biometricsChanged(in context: LAContext) -> Bool {
        guard let currentState = context.evaluatedPolicyDomainState, let previousState = previousDomainState else {
            return false
        }
        return currentState != previousState
    }
    
}

public struct AppLockRules: Decodable {
    public let useBiometricsOrAccountPassword: Bool
    public let forceAppLock: Bool
    public let appLockTimeout: UInt
    
    public static func fromBundle() -> AppLockRules {
        if let fileURL = Bundle.main.url(forResource: "session_manager", withExtension: "json"),
            let fileData = try? Data(contentsOf: fileURL) {
            return fromData(fileData)
        } else {
            fatalError("session_manager.json not exist")
        }
    }
    
    public static func fromData(_ data: Data) -> AppLockRules {
        let decoder = JSONDecoder()
        return try! decoder.decode(AppLockRules.self, from: data)
    }
}
