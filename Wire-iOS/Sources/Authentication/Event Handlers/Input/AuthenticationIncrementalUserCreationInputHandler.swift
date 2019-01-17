//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
 * Handles input during the incremental user creation.
 */

class AuthenticationIncrementalUserCreationInputHandler: AuthenticationEventHandler {

    weak var statusProvider: AuthenticationStatusProvider?

    func handleEvent(currentStep: AuthenticationFlowStep, context: Any) -> [AuthenticationCoordinatorAction]? {
        // Only handle input during the incremental user creation.
        guard case .incrementalUserCreation(_, let step) = currentStep else {
            return nil
        }

        // Only handle string values
        guard let input = context as? String else {
            return nil
        }

        // Only handle input during name and password steps
        switch step {
        case .setName:
            return [.setUserName(input)]
        case .setPassword:
            return [.setUserPassword(input)]
        default:
            return nil
        }
    }

}
