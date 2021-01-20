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

        var _authenticationResult: AppLockController.AuthenticationResult = .unavailable
        var _evaluationContext = LAContext()
        var _passcode: String?

        // MARK: - Properties

        var delegate: AppLockDelegate?

        var isActive = false

        var isLocked = false

        var requiresBiometrics = false

        var needsToSetCustomPasscode = false

        var isCustomPasscodeNotSet = false

        var needsToNotifyUser = false

        var timeout: UInt = 10

        var isForced = false

        var isAvailable = false

        // MARK: - Methods

        func open() {
            methodCalls.open.append(())
        }

        // TODO: Delete

        func evaluateAuthentication(scenario: AppLockController.AuthenticationScenario,
                                    description: String,
                                    context: LAContextProtocol,
                                    with callback: @escaping (AppLockController.AuthenticationResult, LAContextProtocol) -> Void) {
            fatalError()
        }

        func evaluateAuthentication(passcodePreference: AppLockPasscodePreference,
                                    description: String,
                                    context: LAContextProtocol,
                                    callback: @escaping (AuthenticationResult, LAContextProtocol) -> Void) {

            methodCalls.evaluateAuthentication.append((passcodePreference, description, callback))
            callback(_authenticationResult, _evaluationContext)
        }

        func persistBiometrics() {
            methodCalls.persistBiometrics.append(())
        }

        func deletePasscode() throws {
            methodCalls.deletePasscode.append(())
            _passcode = nil
        }

        func storePasscode(_ passcode: String) throws {
            methodCalls.storePasscode.append(passcode)
            _passcode = passcode
        }

        func fetchPasscode() -> Data? {
            methodCalls.fetchPasscode.append(())
            return _passcode?.data(using: .utf8)
        }

    }

}

extension AppLockModule.MockAppLockController {

    struct MethodCalls {

        typealias Preference = AppLockPasscodePreference
        typealias Callback = (AppLockModule.AuthenticationResult, LAContext) -> Void

        var open: [Void] = []
        var evaluateAuthentication: [(preference: Preference, description: String, callback: Callback)] = []
        var persistBiometrics: [Void] = []
        var deletePasscode: [Void] = []
        var storePasscode: [String] = []
        var fetchPasscode: [Void] = []

    }

}
