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
 * A type of view controller that can be managed by an authentication coordinator.
 */

typealias AuthenticationStepViewController = UIViewController & AuthenticationCoordinatedViewController

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

        case .reauthenticate(let credentials, let numberOfAccounts):
            let registrationViewController = RegistrationViewController(authenticationFlow: .onlyLogin)
            registrationViewController.shouldHideCancelButton = numberOfAccounts < 2
            registrationViewController.loginCredentials = credentials
            return registrationViewController

        case .provideCredentials(let credentialsFlowType):
            switch credentialsFlowType {
            case .email:
                let emailLoginStep = LogInWithEmailStepDescription()
                return createViewController(for: emailLoginStep)
            case .phone:
                let phoneLoginStep = LogInWithPhoneNumberStepDescription()
                return createViewController(for: phoneLoginStep, viewControllerType: PhoneNumberAuthenticationStepController.self)
            }

        case .createCredentials(_, let credentialsFlowType):
            switch credentialsFlowType {
            case .email:
                let emailStep = SetPersonalEmailStepDescription()
                return createViewController(for: emailStep)
            case .phone:
                let phoneStep = SetPhoneStepDescription()
                return createViewController(for: phoneStep, viewControllerType: PhoneNumberAuthenticationStepController.self)
            }

        case .clientManagement(let clients, let credentials):
            let emailCredentials = credentials.map { ZMEmailCredentials(email: $0.email!, password: $0.password!) }
            let flow = ClientUnregisterFlowViewController(clientsList: clients, credentials: emailCredentials)
            return AdaptiveFormViewController(childViewController: flow)

        case .noHistory(_, let type):
            let noHistory = NoHistoryViewController(contextType: type)
            return AdaptiveFormViewController(childViewController: noHistory)

        case .enterLoginCode(let phoneNumber):
            let verifyPhoneStep = VerifyPhoneStepDescription(phoneNumber: phoneNumber)
            return createViewController(for: verifyPhoneStep)

        case .addEmailAndPassword(_, _, let canSkip):
            let addEmailPasswordViewController = AddEmailPasswordViewController()
            addEmailPasswordViewController.canSkipStep = canSkip
            return AdaptiveFormViewController(childViewController: addEmailPasswordViewController)

        case .enterActivationCode(let credentials, _):
            let step: TeamCreationStepDescription

            switch credentials {
            case .email(let email):
                step = VerifyEmailStepDescription(email: email)
            case .phone(let phoneNumber):
                step = VerifyPhoneStepDescription(phoneNumber: phoneNumber)
            }

            return createViewController(for: step)

        case .pendingEmailLinkVerification(let emailCredentials):
            let verification = EmailLinkVerificationViewController(credentials: emailCredentials)
            return AdaptiveFormViewController(childViewController: verification)

        case .incrementalUserCreation(let user, let registrationStep):
            return makeRegistrationStepViewController(for: registrationStep, user: user)

        case .teamCreation(let state):
            return makeTeamCreationStepViewController(for: state)

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
        case .setName:
            let nameStep = SetFullNameStepDescription()
            return createViewController(for: nameStep)
        case .setPassword:
            let passwordStep = SetPasswordStepDescription()
            return createViewController(for: passwordStep)
        default:
            return nil
        }
    }

    /**
     * Returns the view controller that displays the interface for the given team creation step.
     *
     * - parameter step: The step to create an interface for.
     * - returns: The view controller to use for this step, or `nil` if the interface builder
     * does not support this step.
     */

    private func makeTeamCreationStepViewController(for state: TeamCreationState) -> AuthenticationStepViewController? {
        var stepDescription: TeamCreationStepDescription

        switch state {
        case .setTeamName:
            stepDescription = SetTeamNameStepDescription()
        case .setEmail:
            stepDescription = SetEmailStepDescription()
        case let .verifyEmail(teamName: _, email: email):
            stepDescription = VerifyEmailStepDescription(email: email)
        case .setFullName:
            stepDescription = SetFullNameStepDescription()
        case .setPassword:
            stepDescription = SetPasswordStepDescription()
        case .inviteMembers:
            return TeamMemberInviteViewController()
        default:
            return nil
        }

        return createViewController(for: stepDescription)
    }

    /// Creates the view controller for team description.
    private func createViewController(for description: TeamCreationStepDescription, viewControllerType: AuthenticationStepController.Type = AuthenticationStepController.self) -> AuthenticationStepController {
        let controller = viewControllerType.init(description: description)

        let mainView = description.mainView
        mainView.valueSubmitted = controller.valueSubmitted

        mainView.valueValidated = { (error: TextFieldValidator.ValidationError) in
            switch error {
            case .none:
                controller.clearError()
            default:
                controller.displayError(error)
            }
        }

        return controller
    }

}
