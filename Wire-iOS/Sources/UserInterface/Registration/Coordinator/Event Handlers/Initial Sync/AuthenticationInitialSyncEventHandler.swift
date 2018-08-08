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
 * Handles the initial sync event.
 *
 * It checks for automation environment, the current step and asks the user for e-mail and password if needed.
 */

class AuthenticationInitialSyncEventHandler: NSObject, AuthenticationEventHandler {

    weak var contextProvider: AuthenticationContextProvider?

    func handleEvent(currentStep: AuthenticationFlowStep, context: Void) -> [AuthenticationEventResponseAction]? {
        // Skip email/password prompt for @fastLogin automation
        guard AutomationHelper.sharedHelper.automationEmailCredentials == nil else {
            return [.hideLoadingView, .completeLoginFlow]
        }

        // Do not ask for credentials again (slow sync can be called multiple times)
        if case .addEmailAndPassword = currentStep {
            return [.hideLoadingView, .completeLoginFlow]
        }

        guard let selfUser = contextProvider?.selfUser, let profile = contextProvider?.selfUserProfile else {
            return nil
        }

        // Check if the user needs email and password
        let registered = contextProvider?.authenticatedUserWasRegisteredOnThisDevice ?? false
        let needsEmail = contextProvider?.authenticatedUserNeedsEmailCredentials ?? false

        if !registered {
            return [.hideLoadingView, .completeLoginFlow]
        }

        if !needsEmail {
            return [.hideLoadingView, .completeRegistrationFlow]
        }

        let nextStep = AuthenticationFlowStep.addEmailAndPassword(user: selfUser, profile: profile, canSkip: false)
        return [.hideLoadingView, .transition(nextStep, resetStack: true)]
    }

}
