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
import WireSyncEngine

typealias ValueSubmitted = (String) -> ()
typealias ValueValidated = (TextFieldValidator.ValidationError) -> ()

protocol ViewDescriptor: class {
    func create() -> UIView
}

protocol ValueSubmission: class {
    var acceptsInput: Bool { get set }
    var valueSubmitted: ValueSubmitted? { get set }
    var valueValidated: ValueValidated? { get set }
}

final class TeamCreationFlowController: NSObject {
    var currentState: TeamCreationState = .setTeamName
    let navigationController: UINavigationController
    let registrationStatus: RegistrationStatus
    var nextState: TeamCreationState?
    var currentController: TeamCreationStepController?
    weak var registrationDelegate: RegistrationViewControllerDelegate?
    var syncToken: Any?
    var sessionManagerToken: Any?
    let tracker = AnalyticsTracker(context: AnalyticsContextRegistrationEmail)!

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
        let mainView = description.mainView
        mainView.valueSubmitted = { [weak self] (value: String) in
            self?.advanceState(with: value)
        }

        mainView.valueValidated = { [weak self] (error: TextFieldValidator.ValidationError) in
            switch error {
            case .none:
                self?.currentController?.clearError()
            default:
                self?.currentController?.displayError(error)
            }
        }

        let backButton = description.backButton
        backButton?.buttonTapped = { [weak self] in
            self?.rewindState()
        }

        let controller = TeamCreationStepController(description: description)
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
            currentController?.showLoadingView = true
            registrationStatus.sendActivationCode(to: email) // Sending activation code to email
        case let .setFullName(teamName: _, email: email, activationCode: activationCode):
            currentController?.showLoadingView = true
            registrationStatus.checkActivationCode(email: email, code: activationCode)
        case .setPassword:
            pushNext()
        case let .createTeam(teamName: teamName, email: email, activationCode: activationCode, fullName: fullName, password: password):
            UIAlertController.requestTOSApproval(over: navigationController) { [weak self] accepted in
                if accepted {
                    self?.currentController?.showLoadingView = true
                    let teamToRegister = TeamToRegister(teamName: teamName, email: email, emailCode:activationCode, fullName: fullName, password: password, accentColor: ZMUser.pickRandomAcceptableAccentColor())
                    self?.registrationStatus.create(team: teamToRegister)
                    self?.tracker.tagTeamCreationAcceptedTerms()
                }
            }
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
        case .createTeam:
            fatal("No controller should be pushed, we have already registered a team!")
        }

        if let description = stepDescription {
            let controller = createViewController(for: description)
            if let current = currentController, current.stepDescription.shouldSkipFromNavigation() {
                currentController = controller
                let withoutLast = navigationController.viewControllers.dropLast()
                let controllers = withoutLast + [controller]
                navigationController.setViewControllers(Array(controllers), animated: true)
            } else {
                currentController = controller
                navigationController.pushViewController(controller, animated: true)
            }
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
            self.currentController = navigationController.viewControllers.last as? TeamCreationStepController
        } else {
            currentState = .setTeamName
            self.nextState = nil
            self.currentController = nil
            self.navigationController.popToRootViewController(animated: true)
        }
    }
}

extension TeamCreationFlowController: VerifyEmailStepDescriptionDelegate {
    func resendActivationCode(to email: String) {
        currentController?.showLoadingView = true
        registrationStatus.sendActivationCode(to: email)
    }

    func changeEmail() {
        rewindState()
    }
}

extension TeamCreationFlowController: SessionManagerCreatedSessionObserver {
    func sessionManagerCreated(userSession : ZMUserSession) {
        syncToken = ZMUserSession.addInitialSyncCompletionObserver(self, userSession: userSession)
        URLSession.shared.dataTask(with: URL(string: UnsplashRandomImageHiQualityURL)!) { (data, _, error) in
            if let data = data, error == nil {
                DispatchQueue.main.async {
                    SessionManager.shared?.unauthenticatedSession?.setProfileImage(imageData: data)
                }
            }
        }.resume()
        sessionManagerToken = nil
    }
}

extension TeamCreationFlowController: ZMInitialSyncCompletionObserver {
    func initialSyncCompleted() {
        currentController?.showLoadingView = false
        registrationDelegate?.registrationViewControllerDidCompleteRegistration()
        syncToken = nil
    }
}

extension TeamCreationFlowController: RegistrationStatusDelegate {
    public func teamRegistered() {
        sessionManagerToken = SessionManager.shared?.addSessionManagerCreatedSessionObserver(self)
        tracker.tagTeamCreated()
    }

    public func teamRegistrationFailed(with error: Error) {
        currentController?.showLoadingView = false
        currentController?.displayError(error)
    }

    public func emailActivationCodeSent() {
        currentController?.showLoadingView = false

        switch currentState {
        case .setEmail:
            pushNext()
        case .verifyEmail:
            currentController?.clearError()
        default:
            break
        }
    }

    public func emailActivationCodeSendingFailed(with error: Error) {
        currentController?.showLoadingView = false
        currentController?.displayError(error)
    }

    public func emailActivationCodeValidated() {
        currentController?.showLoadingView = false
        pushNext()
        tracker.tagTeamCreationEmailVerified()
    }

    public func emailActivationCodeValidationFailed(with error: Error) {
        currentController?.showLoadingView = false
        currentController?.displayError(error)
    }

}
