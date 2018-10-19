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
 * Handles the success of the send activation code request.
 */

class RegistrationActivationCodeSentEventHandler: AuthenticationEventHandler {

    weak var statusProvider: AuthenticationStatusProvider?

    func handleEvent(currentStep: AuthenticationFlowStep, context: Void) -> [AuthenticationCoordinatorAction]? {
        // Only handle email activation success
        guard case let .sendActivationCode(credentials, user, isResend) = currentStep else {
            return nil
        }

        // Create the list of actions
        var actions: [AuthenticationCoordinatorAction] = [.hideLoadingView]

        if (!isResend) {
            let nextStep = AuthenticationFlowStep.enterActivationCode(credentials, user: user)
            actions.append(AuthenticationCoordinatorAction.transition(nextStep, resetStack: false))
        } else {
            actions.append(.unwindState(withInterface: false))
        }

        return actions
    }

}
