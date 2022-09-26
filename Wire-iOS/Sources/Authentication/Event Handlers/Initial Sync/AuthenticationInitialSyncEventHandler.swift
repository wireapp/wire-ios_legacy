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
import WireCommonComponents
import WireUtilities

/**
 * Handles the initial sync event.
 */

final class AuthenticationInitialSyncEventHandler: NSObject, AuthenticationEventHandler {

    weak var statusProvider: AuthenticationStatusProvider?

    func handleEvent(currentStep: AuthenticationFlowStep, context: Void) -> [AuthenticationCoordinatorAction]? {
        // Skip email/password prompt for @fastLogin automation
        guard AutomationHelper.sharedHelper.automationEmailCredentials == nil else {
            return [.hideLoadingView, .completeLoginFlow]
        }

        // Do not ask for credentials again (slow sync can be called multiple times)
        guard case let .pendingInitialSync(nextRegistrationStep) = currentStep else {
            return [.hideLoadingView]
        }

        // Build the list of actions
        var actions: [AuthenticationCoordinatorAction] = [.hideLoadingView]

        if let nextStep = nextRegistrationStep {
            actions.append(.transition(nextStep, mode: .reset))
        } else {
            actions.append(postAction)
        }

        return actions
    }

}
