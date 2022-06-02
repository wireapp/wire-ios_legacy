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
 * A fallback error handler for registration errors.
 */

class ClientRegistrationErrorEventHandler: AuthenticationEventHandler {

    weak var statusProvider: AuthenticationStatusProvider?

    func handleEvent(currentStep: AuthenticationFlowStep, context: (NSError, UUID)) -> [AuthenticationCoordinatorAction]? {
        let (error, _) = context

        // Only handle needsToRegisterEmailToRegisterClient errors
        if error.userSessionErrorCode == .needsToRegisterEmailToRegisterClient {
            // If we are already registering the credentials, do not handle the error
            switch currentStep {
            case .addEmailAndPassword, .registerEmailCredentials, .pendingEmailLinkVerification:
                return nil
            default:
                break
            }
        }

        let alert = AuthenticationCoordinatorErrorAlert(error: error, completionActions: [.unwindState(withInterface: false)])
        return [.hideLoadingView, .presentErrorAlert(alert)]
    }

}
