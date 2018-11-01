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
 * Handles reauthentication errors sent at the start of the flow.
 */

class AuthenticationStartReauthenticateErrorHandler: AuthenticationEventHandler {

    weak var statusProvider: AuthenticationStatusProvider?

    func handleEvent(currentStep: AuthenticationFlowStep, context: (NSError?, Int)) -> [AuthenticationCoordinatorAction]? {
        let (optionalError, numberOfAccounts) = context

        // Only handle errors on launch
        guard case .start = currentStep else {
            return nil
        }

        // If there is no error, we don't need to reauthenticate
        guard let error = optionalError else {
            return nil
        }

        // Only handle reauthentication errors
        let supportedErrors: [ZMUserSessionErrorCode] = [
            .clientDeletedRemotely,
            .accessTokenExpired,
            .needsPasswordToRegisterClient
         ]

        guard supportedErrors.contains(error.userSessionErrorCode) else {
            return nil
        }

        guard numberOfAccounts >= 1 else {
            return nil
        }

        guard let loginCredentials = error.userInfo[ZMUserLoginCredentialsKey] as? LoginCredentials else {
            return nil
        }

        // Prepare the next step
        let nextStep = AuthenticationFlowStep.reauthenticate(credentials: loginCredentials, numberOfAccounts: numberOfAccounts)
        return [.transition(nextStep, resetStack: true)]
    }

}
