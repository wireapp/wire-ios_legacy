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

import UIKit

/**
 * An object that builds view controllers for authentication steps.
 */

class AuthenticationInterfaceBuilder {

    /**
     * Returns the view controller that displays the interface of the authentication step.
     *
     * - note: When new steps are added to the list of steps, you need to handle them here,
     * otherwise the method will return `nil`.
     *
     * - parameter step: The step to create an interface for.
     * - returns: The view controller to use for this step, or `nil` if the interface builder
     * does not support this step.
     */

    func makeViewController(for step: AuthenticationFlowStep) -> AuthenticationStepViewController? {
        switch step {
        case .landingScreen:
            return LandingViewController()

        case .reauthenticate(let error, let numberOfAccounts):
            let registrationViewController = RegistrationViewController()
            registrationViewController.shouldHideCancelButton = numberOfAccounts <= 1
            registrationViewController.signInError = error
            return registrationViewController

        case .provideCredentials:
            let loginViewController = RegistrationViewController(authenticationFlow: .onlyLogin)
            loginViewController.shouldHideCancelButton = true
            return loginViewController

        case .createCredentials:
            let registrationViewController = RegistrationViewController(authenticationFlow: .onlyRegistration)
            registrationViewController.shouldHideCancelButton = true
            return registrationViewController

        case .clientManagement(let clients, let credentials):
            let emailCredentials = ZMEmailCredentials(email: credentials.email!, password: credentials.password!)
            return ClientUnregisterFlowViewController(clientsList: clients, credentials: emailCredentials)

        case .noHistory(_, let type):
            return NoHistoryViewController(contextType: type)

//        case .verifyPhoneNumber(let phoneNumber, _, _):
//            let verificationController = PhoneVerificationStepViewController()
//            verificationController.phoneNumber = phoneNumber
//            return verificationController

        case .addEmailAndPassword(_, _, let canSkip):
            let addEmailPasswordViewController = AddEmailPasswordViewController()
            addEmailPasswordViewController.canSkipStep = canSkip
            return addEmailPasswordViewController

//        case .verifyEmailCredentials(let credentials):
//            let verificationController = EmailVerificationViewController(credentials: credentials)
//            return verificationController

        case .enterActivationCode(let credentials, _):
            switch credentials {
            case .phone(let phoneNumber):
                return VerificationCodeStepViewController(phoneNumber: phoneNumber)
            case .email(let emailAddress):
                return VerificationCodeStepViewController(emailAddress: emailAddress)
            }

        case .incrementalUserCreation(let user, let registrationStep):
            return makeRegistrationStepViewController(for: registrationStep, user: user)

        default:
            return nil
        }
    }

    /**
     * Returns the view controller that displays the interface for the given intermediate
     * registration step.
     *
     * - parameter step: The step to create an interface for.
     * - parameter user: The unregistered user that is being created.
     * - returns: The view controller to use for this step, or `nil` if the interface builder
     * does not support this step.
     */

    private func makeRegistrationStepViewController(for step: IntermediateRegistrationStep, user: UnregisteredUser) -> AuthenticationStepViewController? {
        switch step {
        case .start:
            return nil
        case .reviewTermsOfService:
            return TermsOfUseStepViewController()
        case .provideMarketingConsent:
            return nil
        case .setName:
            return NameStepViewController()
        case .setProfilePicture:
            return ProfilePictureStepViewController(displayName: user.name)
        }
    }

}
