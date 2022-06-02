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
 * Handles button taps in the authentication flow.
 */

class AuthenticationButtonTapInputHandler: AuthenticationEventHandler {

    weak var statusProvider: AuthenticationStatusProvider?

    func handleEvent(currentStep: AuthenticationFlowStep, context: Any) -> [AuthenticationCoordinatorAction]? {
        // Only handle button taps values.
        guard context is Void else {
            return nil
        }

        // Only handle input during specified steps.
        switch currentStep {
        case .noHistory:
            return [.showLoadingView, .configureNotifications, .completeBackupStep]
        case .clientManagement(let clients, let credentials):
            let nextStep = AuthenticationFlowStep.deleteClient(clients: clients, credentials: credentials)
            return [AuthenticationCoordinatorAction.transition(nextStep, mode: .normal)]
        case .pendingEmailLinkVerification:
            return [.repeatAction]
        default:
            return nil
        }
    }

}
