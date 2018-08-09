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
 * Handles the case when the session becomes unauthenticated after the user reauthenticates
 * and that they need to delete clients.
 */

class AuthenticationStartClientDeletionErrorHandler: AuthenticationEventHandler {

    weak var statusProvider: AuthenticationStatusProvider?

    func handleEvent(currentStep: AuthenticationFlowStep, context: (NSError?, Int)) -> [AuthenticationCoordinatorAction]? {
        let (optionalError, _) = context

        // If we already are in the client management step, do nothing
        if case .clientManagement = currentStep {
            return []
        }

        // Only handle this case if the current step is authenticateEmailCredentials
        guard case let .authenticateEmailCredentials(credentials) = currentStep else {
            return nil
        }

        // Only handle canNotRegisterMoreClients errors
        guard let error = optionalError else {
            return nil
        }

        guard error.userSessionErrorCode == .canNotRegisterMoreClients else {
            return nil
        }

        // Prepare the next step
        guard let nextStep = AuthenticationFlowStep.makeClientManagementStep(from: error, credentials: credentials, statusProvider: self.statusProvider) else {
            return nil
        }

        return [.hideLoadingView, .transition(nextStep, resetStack: true)]
    }

}
