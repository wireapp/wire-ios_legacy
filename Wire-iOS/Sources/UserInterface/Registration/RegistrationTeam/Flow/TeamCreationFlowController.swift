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

    var syncToken: Any?
    var sessionManagerToken: Any?
    var marketingConsent: Bool?

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
    }

    fileprivate func showMarketingConsentDialog(presentViewController: UIViewController) {
        UIAlertController.newsletterSubscriptionDialogWasDisplayed = false
        UIAlertController.showNewsletterSubscriptionDialogIfNeeded(presentViewController: presentViewController) { [weak self] marketingConsent in
            self?.marketingConsent = marketingConsent
        }
    }

    fileprivate func pushController(for state: TeamCreationState) {

        let stepDescription: TeamCreationStepDescription? = nil
        let needsToShowMarketingConsentDialog = false

        if let description = stepDescription {
            let controller = createViewController(for: description)

            let completion = {
                if needsToShowMarketingConsentDialog {
                    self.showMarketingConsentDialog(presentViewController: self.navigationController)
                }
            }

            if let current = currentController, current.stepDescription.shouldSkipFromNavigation() {
                currentController = controller
                let withoutLast = navigationController.viewControllers.dropLast()
                let controllers = withoutLast + [controller]
                navigationController.setViewControllers(Array(controllers), animated: true, completion: completion)
            } else {
                currentController = controller
                navigationController.pushViewController(controller, animated: true, completion: completion)
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
    }
}

extension TeamCreationFlowController: VerifyEmailStepDescriptionDelegate {
    func resendActivationCode(to email: String) {
        currentController?.showLoadingView = true
        registrationStatus.sendActivationCode(to: .email(email))
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
                    userSession.profileUpdate.updateImage(imageData: data)
                }
            }
        }.resume()
        sessionManagerToken = nil
    }
}

extension TeamCreationFlowController: ZMInitialSyncCompletionObserver {
    func initialSyncCompleted() {
        currentController?.showLoadingView = false
        advanceState(with: "")
        syncToken = nil
    }
}

extension TeamCreationFlowController: RegistrationStatusDelegate {
    public func teamRegistered() {
        sessionManagerToken = SessionManager.shared?.addSessionManagerCreatedSessionObserver(self)
        Analytics.shared().tagTeamCreated(context: "email")
    }

    public func teamRegistrationFailed(with error: Error) {
        currentController?.showLoadingView = false
        currentController?.displayError(error)
    }

    public func activationCodeSent() {
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

    public func activationCodeSendingFailed(with error: Error) {
        currentController?.showLoadingView = false
        currentController?.displayError(error)
    }

    public func activationCodeValidated() {
        currentController?.showLoadingView = false
        pushNext()
        Analytics.shared().tagTeamCreationEmailVerified(context: "email")
    }

    public func activationCodeValidationFailed(with error: Error) {
        currentController?.showLoadingView = false
        currentController?.displayError(error)
    }

    func userRegistered() {
        // no-op
    }

    func userRegistrationFailed(with error: Error) {
        // no-op
    }

}

extension TeamCreationFlowController: TeamMemberInviteViewControllerDelegate {
    
    func teamInviteViewControllerDidFinish(_ controller: TeamMemberInviteViewController) {
        // registrationDelegate?.registrationViewControllerDidCompleteRegistration()
        
        if let marketingConsent = self.marketingConsent, let user = ZMUser.selfUser(), let userSession = ZMUserSession.shared() {
            user.setMarketingConsent(to: marketingConsent, in: userSession, completion: { _ in })
        }
    }
    
}
