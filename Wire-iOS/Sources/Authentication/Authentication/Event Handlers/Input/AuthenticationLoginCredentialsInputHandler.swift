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

/**
 * Handles the input of the phone number or email to log in.
 */

class AuthenticationLoginCredentialsInputHandler: AuthenticationEventHandler {

    weak var statusProvider: AuthenticationStatusProvider?

    func handleEvent(currentStep: AuthenticationFlowStep, context: Any) -> [AuthenticationCoordinatorAction]? {
        // Only handle input during the credentials providing phase.
        guard case .provideCredentials(let type) = currentStep else {
            return nil
        }

        switch type {
        case .email:
            // Only handle email/password tuple values
            guard let input = context as? (String, String) else {
                return nil
            }

            let request = AuthenticationLoginRequest.email(address: input.0, password: input.1)
            return [.startLoginFlow(request)]

        case .phone:
            // Only handle string values
            guard let input = context as? String else {
                return nil
            }

            let request = AuthenticationLoginRequest.phoneNumber(input)
            return [.startLoginFlow(request)]
        }
    }

}
