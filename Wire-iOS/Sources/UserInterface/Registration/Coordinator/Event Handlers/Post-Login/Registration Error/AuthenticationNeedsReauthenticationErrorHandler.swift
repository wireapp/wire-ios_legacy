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
 * Handles client registration errors related to the expiration of the auth token, which requires
 * the user to reauthenticate.
 */

class AuthenticationNeedsReauthenticationErrorHandler: AuthenticationEventHandler {

    weak var statusProvider: AuthenticationStatusProvider?

    func handleEvent(currentStep: AuthenticationFlowStep, context: (NSError, UUID)) -> [AuthenticationEventResponseAction]? {
        let (error, _) = context

        // Only handle needsPasswordToRegisterClient errrors
        guard error.userSessionErrorCode == .needsPasswordToRegisterClient else {
            return nil
        }

        let numberOfAccounts = statusProvider?.numberOfAccounts ?? 0
        let nextStep = AuthenticationFlowStep.reauthenticate(error: error, numberOfAccounts: numberOfAccounts)

        return [.hideLoadingView, .transition(nextStep, resetStack: true)]
    }

}
