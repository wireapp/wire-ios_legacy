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

        var _authenticationResult: AppLockController.AuthenticationResult = .unavailable
        var _evaluationContext = LAContext()

        func evaluateAuthentication(scenario: AppLockController.AuthenticationScenario,
                                    description: String,
                                    with callback: @escaping (AppLockController.AuthenticationResult, LAContext) -> Void) {
            callback(_authenticationResult, _evaluationContext)
        }

        func persistBiometrics() {
            fatalError("Not implemented")
        }

        func deletePasscode() throws {
            fatalError("Not implemented")
        }

        func storePasscode(_ passcode: String) throws {
            fatalError("Not implemented")
        }

        func fetchPasscode() -> Data? {
            fatalError("Not implemented")
        }

    }

}
