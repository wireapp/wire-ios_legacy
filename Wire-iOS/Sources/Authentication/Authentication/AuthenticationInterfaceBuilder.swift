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
     * The object to use when checking for features. Defaults to the build settings.
     */

    let featureProvider: AuthenticationFeatureProvider

    // MARK: - Initialization

    init(featureProvider: AuthenticationFeatureProvider) {
        self.featureProvider = featureProvider
    }

    // MARK: - Interface Building

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
            print(credentials as Any)
            print(numberOfAccounts as Any)
            let emailLoginStep = ReauthenticateStepDescription()
            return createViewController(for: emailLoginStep)

        case .provideCredentials(let credentialsFlowType):
            let viewController: AuthenticationStepController!

            switch credentialsFlowType {
            case .email:
                let emailLoginStep = LogInWithEmailStepDescription(enablePhoneLogin: !featureProvider.allowOnlyEmailLogin)
                viewController = createViewController(for: emailLoginStep)
            case .phone:
                let phoneLoginStep = LogInWithPhoneNumberStepDescription()
                viewController = createViewController(for: phoneLoginStep, viewControllerType: PhoneNumberAuthenticationStepController.self)
            }

            // Add the item to start company login.
            if featureProvider.allowCompanyLogin {
                viewController.setRightItem("signin.company_idp.button.title".localized, withAction: .startCompanyLogin)
            }

            return viewController

        case .createCredentials(_, let credentialsFlowType):
            switch credentialsFlowType {
            case .email:
                let emailStep = SetPersonalEmailStepDescription()
                return createViewController(for: emailStep)
            case .phone:
                let phoneStep = SetPhoneStepDescription()
                return createViewController(for: phoneStep, viewControllerType: PhoneNumberAuthenticationStepController.self)
            }

        case .clientManagement:
            let manageClientsInvitation = ClientUnregisterInvitationStepDescription()
            return createViewController(for: manageClientsInvitation)

        case .deleteClient(let clients, let credentials):
            return RemoveClientStepViewController(clients: clients, credentials: credentials)

        case .noHistory(_, let context):
            let backupStep = BackupRestoreStepDescription(context: context)
            return createViewController(for: backupStep)

        case .enterLoginCode(let phoneNumber):
            let verifyPhoneStep = VerifyPhoneStepDescription(phoneNumber: phoneNumber, allowChange: false)
            return createViewController(for: verifyPhoneStep)

        case .addEmailAndPassword:
            let addCredentialsStep = AddEmailPasswordStepDescription()
            return createViewController(for: addCredentialsStep)

        case .enterActivationCode(let credentials, _):
            let step: TeamCreationStepDescription

            switch credentials {
            case .email(let email):
                step = VerifyEmailStepDescription(email: email)
            case .phone(let phoneNumber):
                step = VerifyPhoneStepDescription(phoneNumber: phoneNumber, allowChange: false)
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
