//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

typealias ValueSubmitted = (String) -> ()

protocol ViewDescriptor: class {
    func create() -> UIView
}

protocol ValueSubmission: class {
    var valueSubmitted: ValueSubmitted? { get set }
}

final class TeamCreationFlowController: NSObject {
    var currentState: TeamCreationState = .setTeamName
    let navigationController: UINavigationController
    let registrationStatus: RegistrationStatus
    var nextState: TeamCreationState?
    var currentController: TeamCreationStepController!

    init(navigationController: UINavigationController, registrationStatus: RegistrationStatus) {
        self.navigationController = navigationController
        self.registrationStatus = registrationStatus
        super.init()
        registrationStatus.delegate = self
    }

    func startFlow() {
        pushController(for: currentState)
    }

}

// MARK: - Creating step controller
extension TeamCreationFlowController {
    func createViewController(for description: TeamCreationStepDescription) -> TeamCreationStepController {
        let mainView = description.mainViewDescription
        mainView.valueSubmitted = { [weak self] (value: String) in
            self?.advanceState(with: value)
        }

        let backButton = description.backButtonDescription
        backButton?.buttonTapped = { [weak self] in
            self?.rewindState()
        }

        let controller = TeamCreationStepController(headline: description.headline,
                                                    subtext: description.subtext,
                                                    mainView: mainView,
                                                    backButton: backButton,
                                                    secondaryViews: description.secondaryViews)
        return controller
    }
}

// MARK: - State changes
extension TeamCreationFlowController {
    fileprivate func advanceState(with value: String) {
        self.nextState = currentState.nextState(with: value) // Calculate next state
        if let next = self.nextState {
            advanceIfNeeded(to: next)
        }
    }

    fileprivate func advanceIfNeeded(to next: TeamCreationState) {
        switch next {
        case .setTeamName:
            nextState = nil // Nothing to do
        case .setEmail:
            pushNext() // Pushing email step
        case let .verifyEmail(teamName: _, email: email):
            registrationStatus.sendActivationCode(to: email) // Sending activation code to email
        case let .setFullName(teamName: _, email: email, activationCode: activationCode):
            registrationStatus.checkActivationCode(email: email, code: activationCode)
        case .setPassword:
            pushNext()
        }
    }

    fileprivate func pushController(for state: TeamCreationState) {

        var stepDescription: TeamCreationStepDescription?

        switch state {
        case .setTeamName:
            stepDescription = SetTeamNameStepDescription(controller: navigationController)
        case .setEmail:
            stepDescription = SetEmailStepDescription(controller: navigationController)
        case let .verifyEmail(teamName: _, email: email):
            stepDescription = VerifyEmailStepDescription(email: email, delegate: self)
        case .setFullName:
            stepDescription = SetFullNameStepDescription()
        case .setPassword:
            stepDescription = SetPasswordStepDescription()
        }

        if let description = stepDescription {
            currentController = createViewController(for: description)
            navigationController.pushViewController(currentController, animated: true)
        }
    }

    fileprivate func pushNext() {
        if let next = self.nextState {
            currentState = next
            nextState = nil
            pushController(for: next)
        }
    }

    fileprivate func rewindState() {
        if let nextState = currentState.previousState {
            currentState = nextState
            self.nextState = nil
            self.navigationController.popViewController(animated: true)
        } else {
            currentState = .setTeamName
            self.nextState = nil
            self.navigationController.popToRootViewController(animated: true)
        }
    }
}

extension TeamCreationFlowController: VerifyEmailStepDescriptionDelegate {
    func resendActivationCode(to email: String) {
        registrationStatus.sendActivationCode(to: email)
    }

    func changeEmail() {
        rewindState()
    }
}

extension TeamCreationFlowController: RegistrationStatusDelegate {
    public func teamRegistered() {
        pushNext()
    }

    public func teamRegistrationFailed(with error: Error) {
        currentController.displayError(error)
    }

    public func emailActivationCodeSent() {
        pushNext()
    }

    public func emailActivationCodeSendingFailed(with error: Error) {
        currentController.displayError(error)
    }

    public func emailActivationCodeValidated() {
        pushNext()
    }

    public func emailActivationCodeValidationFailed(with error: Error) {
        currentController.displayError(error)
    }

}
