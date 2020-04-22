//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
 * Handles the input of the email after log in if the user doesn't have one.
 */

class AuthenticationAddEmailPasswordInputHandler: AuthenticationEventHandler {

    weak var statusProvider: AuthenticationStatusProvider?

    func handleEvent(currentStep: AuthenticationFlowStep, context: Any) -> [AuthenticationCoordinatorAction]? {
        // Only handle input during the add credentials phase.
        guard case .addEmailAndPassword = currentStep else {
            return nil
        }

        // Only handle email/password tuple values
        guard let (email, password) = context as? (String, String) else {
            return nil
        }

        let credentials = ZMEmailCredentials(email: email, password: password)
        return [.addEmailAndPassword(credentials)]
    }

}
