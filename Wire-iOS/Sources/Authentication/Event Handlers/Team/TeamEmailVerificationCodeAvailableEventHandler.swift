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
 * Handles the availability of the team verification code.
 */

class TeamEmailVerificationCodeAvailableEventHandler: AuthenticationEventHandler {

    weak var statusProvider: AuthenticationStatusProvider?

    func handleEvent(currentStep: AuthenticationFlowStep, context: Void) -> [AuthenticationCoordinatorAction]? {
        // Only handle team related codes
        guard case let .teamCreation(teamState) = currentStep else {
            return nil
        }

        guard case let .sendEmailCode(teamName, email, isResend) = teamState else {
            return nil
        }

        // Push verification screen if needed
        var actions: [AuthenticationCoordinatorAction] = [.hideLoadingView]

        if (!isResend) {
            let nextState: TeamCreationState = .verifyEmail(teamName: teamName, email: email)
            let nextStep: AuthenticationFlowStep = .teamCreation(nextState)
            actions.append(.transition(nextStep, resetStack: false))
        } else {
            actions.append(.unwindState(withInterface: false))
        }

        return actions
    }

}
