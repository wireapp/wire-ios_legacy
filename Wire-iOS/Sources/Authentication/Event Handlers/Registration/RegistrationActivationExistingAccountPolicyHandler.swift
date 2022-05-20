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

private typealias AlertStrings = L10n.Localizable.Registration.Alert

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
        default:
            return nil
        }

        // Create the actions
        var actions: [AuthenticationCoordinatorAction] = [.hideLoadingView]

        switch credentials {
        case .email(let email):
            let alert = AuthenticationCoordinatorAlert(title: AlertStrings.AccountExists.title,
                                                       message: AlertStrings.AccountExists.messageEmail,
                                                       actions: [.changeEmail, .login(email: email)])

            actions.append(.presentAlert(alert))

        case .phone(let number):
            let alert = AuthenticationCoordinatorAlert(title: AlertStrings.AccountExists.title,
                                                       message: AlertStrings.AccountExists.messagePhone,
                                                       actions: [.changePhone, .login(phoneNumber: number)])

            actions.append(.presentAlert(alert))
        }

        return actions
    }

}

private extension AuthenticationCoordinatorAlertAction {

    static var changeEmail: Self {
        Self.init(title: AlertStrings.changeEmailAction,
                  coordinatorActions: [.unwindState(withInterface: false), .executeFeedbackAction(.clearInputFields)])
    }

    static var changePhone: Self {
        Self.init(title: AlertStrings.changePhoneAction,
                  coordinatorActions: [.unwindState(withInterface: false), .executeFeedbackAction(.clearInputFields)])
    }

    static func login(email: String) -> Self {
        let credentials = LoginCredentials(emailAddress: email,
                                           phoneNumber: nil,
                                           hasPassword: true,
                                           usesCompanyLogin: false)

        let prefilledCredentials = AuthenticationPrefilledCredentials(primaryCredentialsType: .email,
                                                                      credentials: credentials,
                                                                      isExpired: false)
        return Self.init(title: AlertStrings.changeSigninAction,
                         coordinatorActions: [.transition(.provideCredentials(.email, prefilledCredentials), mode: .replace)])
    }

    static func login(phoneNumber: String) -> Self {
        Self.init(title: AlertStrings.changeSigninAction,
                  coordinatorActions: [.showLoadingView, .performPhoneLoginFromRegistration(phoneNumber: phoneNumber)])
    }
}
