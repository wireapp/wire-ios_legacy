//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireSyncEngine

/**
 * Handles the event that informs the app when the email login verification code is available.
 */

class AuthenticationEmailVerificationRequiredErrorHandler: AuthenticationEventHandler {

    weak var statusProvider: AuthenticationStatusProvider?

    func handleEvent(currentStep: AuthenticationFlowStep, context: NSError) -> [AuthenticationCoordinatorAction]? {
        let error = context

        // Only handle e-mail login errors
        guard case let .authenticateEmailCredentials(credentials) = currentStep else {
            return nil
        }
        // Only handle accountIsPendingVerification error
        guard error.userSessionErrorCode == .accountIsPendingVerification else {
            return nil
        }

        guard let email  = credentials.email else { return nil }
        guard let password = credentials.password else { return nil }

        return [.hideLoadingView, .requestEmailVerificationCode(email: email, password: password)]
    }
}
