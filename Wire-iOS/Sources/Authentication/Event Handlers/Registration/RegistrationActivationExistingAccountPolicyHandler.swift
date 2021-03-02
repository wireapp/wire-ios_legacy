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
import WireDataModel

/**
 * Handles the case that the user tries to register an account with a phone/e-mail that is already registered.
 */

class RegistrationActivationExistingAccountPolicyHandler: AuthenticationEventHandler {

    weak var statusProvider: AuthenticationStatusProvider?

    func handleEvent(currentStep: AuthenticationFlowStep, context: NSError) -> [AuthenticationCoordinatorAction]? {
        let error = context

        // Only handle phoneNumberIsAlreadyRegistered and emailIsAlreadyRegistered errors
        switch error.userSessionErrorCode {
        case .phoneNumberIsAlreadyRegistered, .emailIsAlreadyRegistered:
            break
        default:
            return nil
        }

        // Only handle errors during activation requests
        let credentials: UnverifiedCredentials

        switch currentStep {
        case let .sendActivationCode(userCredentials, _, _):
            credentials = userCredentials
        case let .teamCreation(TeamCreationState.sendEmailCode(_, email, _)):
            credentials = .email(email)
        default:
            return nil
        }

        // Create the actions
        var actions: [AuthenticationCoordinatorAction] = [.hideLoadingView]

        switch credentials {
        case .email(let email):
            let prefilledCredentials = AuthenticationPrefilledCredentials(
                primaryCredentialsType: .email, credentials:
                LoginCredentials(emailAddress: email, phoneNumber: nil, hasPassword: true, usesCompanyLogin: false), isExpired: false
            )

            let changeEmailAction = AuthenticationCoordinatorAlertAction(title: "registration.alert.change_email_action".localized, coordinatorActions: [.unwindState(withInterface: false), .executeFeedbackAction(.clearInputFields)])
            let loginAction = AuthenticationCoordinatorAlertAction(title: "registration.alert.change_signin_action".localized, coordinatorActions: [.transition(.provideCredentials(.email, prefilledCredentials), mode: .replace)])

            let alert = AuthenticationCoordinatorAlert(title: "registration.alert.account_exists.title".localized,
                                                       message: "registration.alert.account_exists.message_email".localized,
                                                       actions: [changeEmailAction, loginAction])

            actions.append(.presentAlert(alert))

        case .phone(let number):
            let changePhoneAction = AuthenticationCoordinatorAlertAction(title: "registration.alert.change_phone_action".localized, coordinatorActions: [.unwindState(withInterface: false), .executeFeedbackAction(.clearInputFields)])
            let loginAction = AuthenticationCoordinatorAlertAction(title: "registration.alert.change_signin_action".localized, coordinatorActions: [.showLoadingView, .performPhoneLoginFromRegistration(phoneNumber: number)])

            let alert = AuthenticationCoordinatorAlert(title: "registration.alert.account_exists.title".localized,
                                                       message: "registration.alert.account_exists.message_phone".localized,
                                                       actions: [changePhoneAction, loginAction])

            actions.append(.presentAlert(alert))
        }

        return actions
    }

}
