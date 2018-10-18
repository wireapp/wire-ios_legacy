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
 * Handles error when addding the e-mail to the user.
 */

class UserEmailUpdateFailureErrorHandler: AuthenticationEventHandler {

    weak var statusProvider: AuthenticationStatusProvider?

    func handleEvent(currentStep: AuthenticationFlowStep, context: NSError) -> [AuthenticationCoordinatorAction]? {
        let error = context as NSError

        // Only handle errors when updating the email
        guard case .registerEmailCredentials = currentStep else {
            return nil
        }

        // Provide actions
        var actions: [AuthenticationCoordinatorAction] = [.hideLoadingView]

        if (error as NSError).userSessionErrorCode == .emailIsAlreadyRegistered {
            let feedbackAction: AuthenticationCoordinatorAction = .executeFeedbackAction(.clearInputFields)
            actions.append(feedbackAction)
        }

        let errorAlert = AuthenticationCoordinatorErrorAlert(error: error, completionActions: [.unwindState(withInterface: false)])
        actions.append(.presentErrorAlert(errorAlert))

        return actions
    }

}
