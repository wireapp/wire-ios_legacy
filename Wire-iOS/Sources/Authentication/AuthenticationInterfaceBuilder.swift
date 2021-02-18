//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import WireDataModel

/**
 * A type of view controller that can be managed by an authentication coordinator.
 */

typealias AuthenticationStepViewController = UIViewController & AuthenticationCoordinatedViewController

/**
 * An object that builds view controllers for authentication steps.
 */

class AuthenticationInterfaceBuilder {

    /// The object to use when checking for features.
    let featureProvider: AuthenticationFeatureProvider

    // MARK: - Initialization

    /**
     * Creates an interface builder with the specified set of features.
     * - parameter featureProvider: The object to use when checking for features
     */

    init(featureProvider: AuthenticationFeatureProvider) {
        self.featureProvider = featureProvider
    }

    // MARK: - Interface Building

    /**
     * Returns the view controller that displays the interface of the authentication step.
     *
     * - note: When new steps are added to the `AuthenticationFlowStep` enum, you need to
     * add a case to handle them here, otherwise the method will return `nil`.
     *
     * - parameter step: The step to create an interface for.
     * - returns: The view controller to use for this step, or `nil` if the interface builder
     * does not support this step.
     */

    func makeViewController(for step: AuthenticationFlowStep) -> AuthenticationStepViewController? {
        switch step {
        case .landingScreen:
            let landingViewController = LandingViewController()
            landingViewController.configure(with: featureProvider)
            return landingViewController

        case .reauthenticate(let credentials, _, let isSignedOut):
            let viewController: AuthenticationStepController

            if credentials?.usesCompanyLogin == true && credentials?.hasPassword == false {
                // Is the user has SSO enabled, show the screen to log in with SSO
                let companyLoginStep = ReauthenticateWithCompanyLoginStepDescription()
                viewController = makeViewController(for: companyLoginStep)

            } else {
                let prefill: AuthenticationPrefilledCredentials?

                if let credentials = credentials {
                    // If we found the credentials of the expired session, pre-fill them
                    let prefillType: AuthenticationCredentialsType = credentials.phoneNumber != nil && credentials.emailAddress == nil ? .phone : .email
                    prefill = AuthenticationPrefilledCredentials(primaryCredentialsType: prefillType, credentials: credentials, isExpired: isSignedOut)
                } else {
                    // Otherwise, default to the email pre-fill screen.
                    prefill = nil
                }

                viewController = makeCredentialsViewController(for: .reauthentication(prefill))
            }

            // Add the bar button item to sign out
            viewController.setRightItem("registration.signin.too_many_devices.sign_out_button.title".localized, withAction: .signOut(warn: true), accessibilityID: "signOutButton")
            return viewController

        case .provideCredentials(let credentialsFlowType, let prefill):
            return makeCredentialsViewController(for: .login(credentialsFlowType, prefill))

        case .createCredentials(_, let credentialsFlowType):
            return makeCredentialsViewController(for: .registration(credentialsFlowType))

        case .passcodeSetup:
            return PasscodeSetupViewController.createKeyboardAvoidingFullScreenView(variant: .light,
                                                                                    context: .createPasscode)
            
        case .clientManagement:
            let manageClientsInvitation = ClientUnregisterInvitationStepDescription()
            let viewController = makeViewController(for: manageClientsInvitation)
            viewController.setRightItem("registration.signin.too_many_devices.sign_out_button.title".localized, withAction: .signOut(warn: true), accessibilityID: "signOutButton")
            return viewController

        case .deleteClient(let clients, let credentials):
            return RemoveClientStepViewController(clients: clients, credentials: credentials)

        case .noHistory(_, let context):
            let backupStep = BackupRestoreStepDescription(context: context)
            return makeViewController(for: backupStep)

        case .enterLoginCode(let phoneNumber):
            let verifyPhoneStep = VerifyPhoneStepDescription(phoneNumber: phoneNumber, allowChange: false)
            return makeViewController(for: verifyPhoneStep)

        case .addEmailAndPassword:
            let addCredentialsStep = AddEmailPasswordStepDescription()
            let viewController = makeViewController(for: addCredentialsStep)
            viewController.setRightItem("registration.signin.too_many_devices.sign_out_button.title".localized, withAction: .signOut(warn: true), accessibilityID: "signOutButton")
            return viewController

        case .enterActivationCode(let credentials, _):
            let step: AuthenticationStepDescription

            switch credentials {
            case .email(let email):
                step = VerifyEmailStepDescription(email: email)
            case .phone(let phoneNumber):
                step = VerifyPhoneStepDescription(phoneNumber: phoneNumber, allowChange: false)
            }

            return makeViewController(for: step)

        case .pendingEmailLinkVerification(let emailCredentials):
            let verifyEmailStep = EmailLinkVerificationStepDescription(emailAddress: emailCredentials.email!)

            let viewController = makeViewController(for: verifyEmailStep)
            viewController.setRightItem("registration.signin.too_many_devices.sign_out_button.title".localized, withAction: .signOut(warn: true), accessibilityID: "signOutButton")
            return viewController

        case .incrementalUserCreation(let user, let registrationStep):
            return makeRegistrationStepViewController(for: registrationStep, user: user)

        case .teamCreation(let state):
            return makeTeamCreationStepViewController(for: state)

        case .switchBackend(let url):
            let viewController = PreBackendSwitchViewController()
            viewController.backendURL = url
            return viewController
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
            return makeViewController(for: nameStep)
        case .setPassword:
            let passwordStep = SetPasswordStepDescription()
            return makeViewController(for: passwordStep)
        default:
            return nil
        }
    }

    /**
     * Returns the view controller that displays the interface for the given team creation step.
     *
     * - parameter state: The team creation step to create an interface for.
     * - returns: The view controller to use for this state, or `nil` if the interface builder
     * does not support this state.
     */

    private func makeTeamCreationStepViewController(for state: TeamCreationState) -> AuthenticationStepViewController? {
        var stepDescription: AuthenticationStepDescription

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

        return makeViewController(for: stepDescription)
    }

    /**
     * Creates a view controller for a step view description.
     *
     * - parameter description: The step to create an interface for.
     * - returns: The view controller to use for this step, or `nil` if the interface builder
     * does not support this step.
     */

    private func makeViewController(for description: AuthenticationStepDescription) -> AuthenticationStepController {
        let controller = AuthenticationStepController(description: description)

        let mainView = description.mainView

        mainView.valueSubmitted = { [weak controller] value in
            controller?.valueSubmitted(value)
        }

        mainView.valueValidated = { [weak controller] validation in
            controller?.valueValidated(validation)
        }

        return controller
    }

    /**
     * Creates and configures an authentication credentials view controller for the specified flow type.
     * - parameter flowType: The type of flow to use in the view controller.
     * - returns: A credentials input view controller configured with the feature provider.
     */

    private func makeCredentialsViewController(for flowType: AuthenticationCredentialsViewController.FlowType) -> AuthenticationCredentialsViewController {
        let viewController = AuthenticationCredentialsViewController(flowType: flowType)
        viewController.configure(with: featureProvider)
        return viewController
    }

}
