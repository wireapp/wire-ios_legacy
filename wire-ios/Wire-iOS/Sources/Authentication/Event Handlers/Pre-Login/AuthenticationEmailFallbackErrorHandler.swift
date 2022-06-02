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
 * Handles error related to e-mail login that were not caught by other handlers.
 * - warning: You need to register this handler after all e-mail error related handlers.
 */

class AuthenticationEmailFallbackErrorHandler: AuthenticationEventHandler {

    weak var statusProvider: AuthenticationStatusProvider?

    func handleEvent(currentStep: AuthenticationFlowStep, context: NSError) -> [AuthenticationCoordinatorAction]? {
        let error = context

        // Only handle e-mail login errors
        guard case .authenticateEmailCredentials = currentStep else {
            return nil
        }

        // Handle the actions
        var actions: [AuthenticationCoordinatorAction] = [.hideLoadingView]

        // Show a guidance dot if the user caused the failure
        if error.userSessionErrorCode != .networkError {
            actions.append(.executeFeedbackAction(.showGuidanceDot))
        }

        let alert = AuthenticationCoordinatorErrorAlert(error: error, completionActions: [.unwindState(withInterface: false)])
        actions.append(.presentErrorAlert(alert))

        return actions
    }

}
