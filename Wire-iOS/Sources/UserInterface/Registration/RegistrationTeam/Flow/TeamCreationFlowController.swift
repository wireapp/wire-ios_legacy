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
    func createViewController(for state: TeamCreationState) -> TeamCreationStepController {
        let mainView = state.mainViewDescription
        mainView.valueSubmitted = { [weak self] (value: String) in
            self?.advanceState(with: value)
        }

        let backButton = state.backButtonDescription
        backButton?.buttonTapped = { [weak self] in
            self?.rewindState()
        }

        let secondaryViews = self.secondaryViews(for: state)
        let controller = TeamCreationStepController(headline: currentState.headline,
                                                    subtext: currentState.subtext,
                                                    mainView: mainView,
                                                    backButton: backButton,
                                                    secondaryViews: secondaryViews)
        return controller
    }

    func secondaryViews(for state: TeamCreationState) -> [ViewDescriptor] {
        switch state  {
        case .setTeamName:
            let whatIsWire = ButtonDescription(title: "What is Wire for teams?", accessibilityIdentifier: "wire_for_teams_button")
            whatIsWire.buttonTapped = { [weak self] in
                let webview = WebViewController(url: URL(string: "https://wire.com")!)
                self?.navigationController.present(webview, animated: true, completion: nil)
            }
            return [whatIsWire]
        case let .verifyEmail(teamName: _, email: email):
            let resendCode = ButtonDescription(title: "Resend code", accessibilityIdentifier: "resend_button")
            resendCode.buttonTapped = { [weak self] in
                self?.registrationStatus.sendActivationCode(to: email)
            }
            let changeEmail = ButtonDescription(title: "Change Email", accessibilityIdentifier: "change_email_button")
            changeEmail.buttonTapped = { [weak self] in
                self?.rewindState()
            }
            return [resendCode, changeEmail]
        case .setEmail, .setFullName, .setPassword:
            return []
        }
    }
}

// MARK: - State changes
extension TeamCreationFlowController {
    fileprivate func advanceState(with value: String) {
        self.nextState = currentState.nextState(with: value) // Calculate next state
        advanceIfNeeded()
    }

    fileprivate func advanceIfNeeded() {
        if let next = self.nextState {
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
    }

    fileprivate func pushController(for state: TeamCreationState) {
        currentController = createViewController(for: state)
        navigationController.pushViewController(currentController, animated: true)
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
