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

/// An app lock abstraction.

public protocol AppLockType {

    var delegate: AppLockDelegate? { get set }

    /// Whether the app lock feature is availble to the user.

    var isAvailable: Bool { get }

    /// Whether the app lock on.

    var isActive: Bool { get set }

    /// Whether the app lock is mandatorily active.

    var isForced: Bool { get }

    /// The maximum number of seconds allowed in the background before the
    /// authentication is required.

    var timeout: UInt { get }

    /// Whether the app lock is currently locked.

    var isLocked: Bool { get }

    /// Whether a custom passcode (rather a device passcode) should be used.

    var requireCustomPasscode: Bool { get }

    /// Whether a custom passcode has been set.

    var isCustomPasscodeSet: Bool { get }

    /// Whether the user needs to be informed about configuration changes.

    var needsToNotifyUser: Bool { get set }

    /// Delete the stored passcode.

    func deletePasscode() throws

    /// Update the stored passcode.

    func updatePasscode(_ passcode: String) throws

    /// Begin the "inactivity" timer.
    ///
    /// This should be called when the user has left the private space being
    /// protected by the app lock, e.g when switching accounts or leaving the app.

    func beginTimer()

    /// Open the app lock.

    func open() throws

    /// Authenticate with device owner credentials (biometrics or passcode).
    ///
    /// - Parameters:
    ///     - passcodePreference: Used to determine which type of passcode is used.
    ///     - description: The message to dispaly in the authentication UI.
    ///     - context: The context in which authentication happens.
    ///     - callback: Invoked with the authentication result.

    func evaluateAuthentication(passcodePreference: AppLockPasscodePreference,
                                description: String,
                                context: LAContextProtocol,
                                callback: @escaping (AppLockAuthenticationResult, LAContextProtocol) -> Void)

    /// Authenticate with a custom passcode.
    ///
    /// - Parameter customPasscode: The user inputted passcode.
    /// - Returns: The authentication result, which should be either `granted` or `denied`.

    func evaluateAuthentication(customPasscode: String) -> AppLockAuthenticationResult

}

public extension AppLockType {

    func evaluateAuthentication(passcodePreference: AppLockPasscodePreference,
                                description: String,
                                callback: @escaping (AppLockAuthenticationResult, LAContextProtocol) -> Void) {

        evaluateAuthentication(passcodePreference: passcodePreference,
                               description: description,
                               context: LAContext(),
                               callback: callback)
    }
}
