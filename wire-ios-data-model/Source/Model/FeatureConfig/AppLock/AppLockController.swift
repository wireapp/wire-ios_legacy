//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import LocalAuthentication

public final class AppLockController: AppLockType {

    static let log = ZMSLog(tag: "AppLockController")

    // MARK: - Properties

    public weak var delegate: AppLockDelegate?

    public var isAvailable: Bool {
        guard legacyConfig == nil else { return true }
        return config.isAvailable
    }

    public var isActive: Bool {
        get {
            return isForced || selfUser.isAppLockActive
        }

        set {
            guard !isForced else { return }
            selfUser.isAppLockActive = newValue
        }
    }

    public var isForced: Bool {
        return legacyConfig?.isForced ?? config.isForced
    }

    public var timeout: UInt {
        return legacyConfig?.timeout ?? config.timeout
    }

    public var isLocked: Bool {
        guard isActive else { return false }

        switch state {
        case .unlocked:
            return false

        case .locked:
            return true

        case .needsChecking:
            state = isTimeoutExceeded ? .locked : .unlocked
            return state == .locked
        }
    }

    public var requireCustomPasscode: Bool {
        return legacyConfig?.requireCustomPasscode ?? false
    }

    public var isCustomPasscodeSet: Bool {
        return fetchPasscode() != nil
    }

    public var needsToNotifyUser: Bool {
        get {
            featureService.needsToNotifyUser(for: .appLock)
        }

        set {
            featureService.setNeedsToNotifyUser(newValue, for: .appLock)
        }
    }

    // MARK: - Private properties

    private let selfUser: ZMUser
    private let featureService: FeatureService

    private(set) var state = State.locked

    private(set) var lastCheckpoint = Date.distantPast

    private var isTimeoutExceeded: Bool {
        let timeSinceAuth = -lastCheckpoint.timeIntervalSinceNow
        let timeoutWindow = 0..<Double(timeout)
        return !timeoutWindow.contains(timeSinceAuth)
    }

    let keychainItem: PasscodeKeychainItem

    var biometricsState: BiometricsStateProtocol = BiometricsState()

    private let legacyConfig: LegacyConfig?

    private var config: Config {
        let appLock = featureService.fetchAppLock()

        return Config(isAvailable: appLock.status == .enabled,
                      isForced: appLock.config.enforceAppLock,
                      timeout: appLock.config.inactivityTimeoutSecs)
    }

    // MARK: - Life cycle

    public init(userId: UUID, selfUser: ZMUser, legacyConfig: LegacyConfig? = nil) {
        precondition(selfUser.isSelfUser, "AppLockController initialized with non-self user")

        // It's safer use userId rather than selfUser.remoteIdentifier!
        self.keychainItem = PasscodeKeychainItem(userId: userId)
        self.selfUser = selfUser
        self.legacyConfig = legacyConfig

        featureService = FeatureService(context: selfUser.managedObjectContext!)
    }

    // MARK: - Methods

    public func beginTimer() {
        guard state == .unlocked else { return }
        state = .needsChecking
        lastCheckpoint = Date()
    }

    /// Open the app lock.
    ///
    /// This method informs the delegate that the app lock opened. The delegate should
    /// then react appropriately by transitioning away from the app lock UI.
    ///
    /// - Throws: AppLockError

    public func open() throws {
        guard !isLocked else { throw AppLockError.authenticationNeeded }
        delegate?.appLockDidOpen(self)
    }

    // MARK: - Authentication

    public func evaluateAuthentication(passcodePreference: AppLockPasscodePreference,
                                       description: String,
                                       context: LAContextProtocol = LAContext(),
                                       callback: @escaping (AppLockAuthenticationResult, LAContextProtocol) -> Void) {
        let policy = passcodePreference.policy
        var error: NSError?
        let canEvaluatePolicy = context.canEvaluatePolicy(policy, error: &error)

        // Changing biometrics in device settings is protected by the device passcode, but if
        // the device passcode isn't considered secure enough, then ask for the custon passcode
        // to accept the new biometrics state.
        if biometricsState.biometricsChanged(in: context) && !passcodePreference.allowsDevicePasscode {
            callback(.needCustomPasscode, context)
            return
        }

        // No device authentication possible, but can fall back to the custom passcode.
        if !canEvaluatePolicy && passcodePreference.allowsCustomPasscode {
            callback(.needCustomPasscode, context)
            return
        }

        guard canEvaluatePolicy else {
            callback(.unavailable, context)
            Self.log.error("Local authentication error: \(String(describing: error?.localizedDescription))")
            return
        }

        context.evaluatePolicy(policy, localizedReason: description) { success, error in
            var result: AppLockAuthenticationResult = success ? .granted : .denied

            if let laError = error as? LAError, laError.code == .userFallback, passcodePreference.allowsCustomPasscode {
                result = .needCustomPasscode
            }

            if result == .granted {
                self.state = .unlocked
            }

            callback(result, context)
        }
    }

    public func evaluateAuthentication(customPasscode: String) -> AppLockAuthenticationResult {
        guard
            let storedPasscode = fetchPasscode(),
            let passcode = customPasscode.data(using: .utf8),
            passcode == storedPasscode
        else {
            return .denied
        }

        state = .unlocked
        biometricsState.persistState()
        return .granted
    }

    // MARK: - Passcode management

    public func updatePasscode(_ passcode: String) throws {
        try deletePasscode()
        try storePasscode(passcode)
    }

    public func deletePasscode() throws {
        try Keychain.deleteItem(keychainItem)
    }

    private func storePasscode(_ passcode: String) throws {
        try Keychain.storeItem(keychainItem, value: passcode.data(using: .utf8)!)
    }

    func fetchPasscode() -> Data? {
        return try? Keychain.fetchItem(keychainItem)
    }

}

// MARK: - TEST ONLY!

extension AppLockController {

    func _setState(_ state: State) {
        self.state = state
    }

    func _setLastCheckpoint(_ checkpoint: Date) {
        lastCheckpoint = checkpoint
    }

}
