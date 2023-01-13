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
import WireSystem

private let zmLog = ZMSLog(tag: "AuthenticationReauthenticateInputHandler")

/**
 * Handles input in the reauthentication phase.
 */

final class AuthenticationReauthenticateInputHandler: AuthenticationEventHandler {

    weak var statusProvider: AuthenticationStatusProvider?

    func handleEvent(currentStep: AuthenticationFlowStep, context: Any) -> [AuthenticationCoordinatorAction]? {
        // Only handle input during the reauthenticate phase.
        guard case .reauthenticate = currentStep else {
            return nil
        }

        if context is Void {
            // If we get `Void`, start the company login flow.
            return [.startCompanyLogin(code: nil)]
        } else if let (emailAndPassword, proxyCredentials) = context as? (EmailPasswordInput, AuthenticationProxyCredentialsInput?) {
            // If we get `(EmailPasswordInput, AuthenticationProxyCredentialsInput?)`, start the email flow
            let request = AuthenticationLoginRequest.email(address: emailAndPassword.email, password: emailAndPassword.password)
            return [.startLoginFlow(request, proxyCredentials)]
        } else if let fullNumber = (context as? PhoneNumber)?.fullNumber {
            // If we get `PhoneNumber`, start the phone login flow
            let request = AuthenticationLoginRequest.phoneNumber(fullNumber)
            return [.startLoginFlow(request, nil)]
        } else {
            zmLog.error("Unable to handle context type: \(type(of: context))")
        }

        // Do not handle other cases.
        return nil
    }

}
