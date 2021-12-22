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
@testable import Wire

extension AppLockModule {

    final class MockAppLockController: AppLockType {

        // MARK: - Metrics

        var methodCalls = MethodCalls()

        // MARK: - Mock helpers

        var _authenticationResult: AppLockAuthenticationResult = .unavailable
        var _evaluationContext = LAContext()
        var _passcode: String?

        // MARK: - Properties

        var delegate: AppLockDelegate?

        var isAvailable = true
        var isActive = false
        var timeout: UInt = 10
        var isForced = false
        var isLocked = false
        var requireCustomPasscode = false
        var isCustomPasscodeSet = false
        var needsToNotifyUser = false

        // MARK: - Methods

        func beginTimer() {
            methodCalls.beginTimer.append(())
        }

        func open() {
            methodCalls.open.append(())
        }

        func evaluateAuthentication(passcodePreference: AppLockPasscodePreference,
                                    description: String,
                                    context: LAContextProtocol,
                                    callback: @escaping (AuthenticationResult, LAContextProtocol) -> Void) {

            methodCalls.evaluateAuthentication.append((passcodePreference, description, callback))
            callback(_authenticationResult, _evaluationContext)
        }

        func evaluateAuthentication(customPasscode: String) -> AuthenticationResult {
            methodCalls.evaluateAuthenticationWithCustomPasscode.append(customPasscode)
            return _passcode == customPasscode ? .granted : .denied
        }

        func deletePasscode() throws {
            methodCalls.deletePasscode.append(())
            _passcode = nil
        }

        func updatePasscode(_ passcode: String) throws {
            methodCalls.updatePasscode.append(passcode)
            _passcode = passcode
        }

    }

}

extension AppLockModule.MockAppLockController {

    struct MethodCalls {

        typealias Preference = AppLockPasscodePreference
        typealias Callback = (AppLockModule.AuthenticationResult, LAContext) -> Void

        var beginTimer: [Void] = []
        var open: [Void] = []
        var evaluateAuthentication: [(preference: Preference, description: String, callback: Callback)] = []
        var evaluateAuthenticationWithCustomPasscode: [String] = []
        var deletePasscode: [Void] = []
        var updatePasscode: [String] = []

    }

}
