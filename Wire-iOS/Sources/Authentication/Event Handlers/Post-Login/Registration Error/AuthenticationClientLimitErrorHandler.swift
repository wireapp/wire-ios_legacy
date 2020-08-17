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
import WireSyncEngine
import WireCommonComponents

/**
 * Handles client registration errors related to the client limit.
 */

class AuthenticationClientLimitErrorHandler: AuthenticationEventHandler {

    weak var statusProvider: AuthenticationStatusProvider?

    func handleEvent(currentStep: AuthenticationFlowStep, context: (NSError, UUID)) -> [AuthenticationCoordinatorAction]? {
        let (error, _) = context

        // Only handle canNotRegisterMoreClients errors
        guard error.userSessionErrorCode == .canNotRegisterMoreClients else {
            return nil
        }

        // Get the credentials to start the deletion
        let authenticationCredentials: ZMCredentials?

        switch currentStep {
        case .noHistory(let credentials, _):
            authenticationCredentials = credentials
        case .authenticateEmailCredentials(let credentials):
            authenticationCredentials = credentials
        default:
            return nil
        }

        guard let nextStep = AuthenticationFlowStep.makeClientManagementStep(from: error, credentials: authenticationCredentials, statusProvider: self.statusProvider) else {
            return nil
        }

        return [.hideLoadingView, .transition(nextStep, mode: .reset)]
    }

}
