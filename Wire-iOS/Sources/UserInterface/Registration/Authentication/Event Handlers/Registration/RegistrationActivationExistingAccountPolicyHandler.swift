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
 * Handles the case that the user tries to register an account with a phone/e-mail that is already registered.
 */

class RegistrationActivationExistingAccountPolicyHandler: AuthenticationEventHandler {

    weak var statusProvider: AuthenticationStatusProvider?

    func handleEvent(currentStep: AuthenticationFlowStep, context: NSError) -> [AuthenticationCoordinatorAction]? {
        let error = context

        // Only handle errors during activation requests
        guard case let .sendActivationCode(_, user, _) = currentStep else {
            return nil
        }

        // Only handle phoneNumberIsAlreadyRegistered and emailIsAlreadyRegistered errors
        switch error.userSessionErrorCode {
        case .phoneNumberIsAlreadyRegistered, .emailIsAlreadyRegistered:
            break
        default:
            return nil
        }

        // Create the actions
        var actions: [AuthenticationCoordinatorAction] = [.hideLoadingView]

        switch user.credentials! {
        case .email:
            let changeEmailAction = AuthenticationCoordinatorAlertAction(title: "Change E-mail", coordinatorActions: [.unwindState, .executeFeedbackAction(.clearInputFields)])
            let loginAction = AuthenticationCoordinatorAlertAction(title: "Sign In", coordinatorActions: [])
            let alert = AuthenticationCoordinatorAlert(title: "Account Exists", message: "The e-mail address you chose to register is already in use. Use another e-mail address, or try to log in if you own this account.", actions: [changeEmailAction, loginAction])
            actions.append(.presentAlert(alert))

        case .phone(let number):
            let changePhoneAction = AuthenticationCoordinatorAlertAction(title: "Change Phone Number", coordinatorActions: [.unwindState, .executeFeedbackAction(.clearInputFields)])
            let loginAction = AuthenticationCoordinatorAlertAction(title: "Sign In", coordinatorActions: [.showLoadingView, .performPhoneLoginFromRegistration(phoneNumber: number)])
            let alert = AuthenticationCoordinatorAlert(title: "Account Exists", message: "The phone number you chose to register is already in use. Use another phone number, or try to log in if you own this account.", actions: [changePhoneAction, loginAction])
            actions.append(.presentAlert(alert))
        }

        return actions
    }

}
