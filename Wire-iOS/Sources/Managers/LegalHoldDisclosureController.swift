//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
 * An object that coordinates disclosing the legal hold state to the user.
 */

class LegalHoldDisclosureController: NSObject, ZMUserObserver {

    enum DisclosureState {
        /// No legal hold status is being disclosed.
        case none

        /// The user is being warned about a pending legal hold alert.
        case warningAboutPendingRequest(UIAlertController)

        /// The user is waiting for the response on the legal hold acceptation.
        case acceptingRequest

        /// The user is being warned about the result of accepting legal hold.
        case warningAboutAcceptationResult(UIAlertController)

        /// The user is being warned about the deactivation of legal hold.
        case warningAboutDisabled(UIAlertController)

        /// The user is being warned about the activation of legal hold.
        case warningAboutEnabled(UIAlertController)

        /// The alert associated with the state, if any.
        var alert: UIAlertController? {
            switch self {
            case .warningAboutEnabled(let alert), .warningAboutDisabled(let alert), .warningAboutPendingRequest(let alert), .warningAboutAcceptationResult(let alert):
                return alert
            case .acceptingRequest, .none:
                return nil
            }
        }
    }

    enum DisclosureCause {
        /// We need to disclose the state because the user opened the app.
        case appOpen

        /// We need to disclose the state because the user tapped a button.
        case userAction

        /// We need to disclose the state because we detected a remote change.
        case remoteUserChange
    }

    // MARK: - Properties

    /// The self user, that can become under legal hold.
    let selfUser: SelfUserType

    /// The user session related to the self user.
    let userSession: ZMUserSession?

    /// The block that presents view controllers when requested.
    let presenter: ViewControllerPresenter

    /// The current state of legal hold disclosure. Defaults to none.
    var currentState: DisclosureState = .none

    private var userObserverToken: Any?

    // MARK: - Initialization

    init(selfUser: SelfUserType, userSession: ZMUserSession?, presenter: @escaping ViewControllerPresenter) {
        self.selfUser = selfUser
        self.userSession = userSession
        self.presenter = presenter
        super.init()

        configureObservers()
    }

    private func configureObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterForeground), name: UIApplication.didBecomeActiveNotification, object: nil)

        if let session = self.userSession {
            userObserverToken = UserChangeInfo.add(observer: self, for: selfUser, userSession: session)
        }
    }

    // MARK: - Notifications

    @objc private func applicationDidEnterForeground() {
        discloseCurrentState(cause: .appOpen)
    }

    // MARK: User Change

    func userDidChange(_ changeInfo: UserChangeInfo) {
        guard changeInfo.legalHoldStatusChanged else {
            return
        }

        discloseCurrentState(cause: .remoteUserChange)
    }

    // MARK: - Alerts

    /// Present the current legal hold state.
    func discloseCurrentState(cause: DisclosureCause) {
        switch selfUser.legalHoldStatus {
        case .enabled:
            // Do not show the alert for a remote change unless it requires attention
            if selfUser.needsToAcknowledgeLegalHoldStatus {
                discloseEnabledStateIfPossible()
            }

        case .pending(let request):
            switch cause {
            case .appOpen, .userAction:
                // Always show the alert when coming into the foreground or when the user requests it
                disclosePendingRequestIfPossible(request)

            case .remoteUserChange:
                // Do not show the alert for a remote change unless it requires attention
                if selfUser.needsToAcknowledgeLegalHoldStatus {
                    disclosePendingRequestIfPossible(request)
                }
            }

        case .disabled:
            // Do not show the alert for a remote change unless it requires attention
            if selfUser.needsToAcknowledgeLegalHoldStatus {
                discloseDisabledStateIfPossible()
            }
        }
    }

    /// Present an alert about legal hold being enabled.
    private func discloseEnabledStateIfPossible() {
        func presentEnabledAlert() {
            let alert = LegalHoldAlertFactory.makeLegalHoldActivatedAlert(
                for: selfUser,
                suggestedStateChangeHandler: assignState
            )

            currentState = .warningAboutEnabled(alert)
            presenter(alert, true, nil)
        }

        switch currentState {
        case .acceptingRequest, .warningAboutEnabled:
            // If we are already accepting the request or it's already accepted, do not show a popup
            return
        default:
            // If there is a current alert, replace it with the latest disclosure
            dismissAlertIfNeeded(currentState.alert, dismissalHandler: presentEnabledAlert)
        }
    }

    /// Present an alert about a pending legal hold request.
    private func disclosePendingRequestIfPossible(_ request: LegalHoldRequest) {
        func presentPendingRequestAlert() {
            let alert = LegalHoldAlertFactory.makeLegalHoldActivationAlert(
                for: request,
                user: selfUser,
                presenter: presenter,
                suggestedStateChangeHandler: assignState
            )

            currentState = .warningAboutPendingRequest(alert)
            presenter(alert, true, nil)
        }

        // If there is a current alert, replace it with the latest disclosure
        dismissAlertIfNeeded(currentState.alert, dismissalHandler: presentPendingRequestAlert)
    }

    private func discloseDisabledStateIfPossible() {
        func presentDisabledAlert() {
            let alert = LegalHoldAlertFactory.makeLegalHoldDeactivatedAlert(
                for: selfUser,
                suggestedStateChangeHandler: assignState
            )

            currentState = .warningAboutDisabled(alert)
            presenter(alert, true, nil)
        }

        // If we are already warning about disabled, do nothing
        if case .warningAboutDisabled = currentState {
            return
        }

        // If there is a current alert, replace it with the latest disclosure
        dismissAlertIfNeeded(currentState.alert, dismissalHandler: presentDisabledAlert)
    }

    // MARK: - Helpers

    /// Dismisses the alert if it's presented, and calls the dismissal handler.
    private func dismissAlertIfNeeded(_ alert: UIAlertController?, dismissalHandler: @escaping () -> Void) {
        if let currentAlert = alert, currentAlert.presentingViewController != nil {
            currentAlert.dismiss(animated: true, completion: dismissalHandler)
        } else {
            dismissalHandler()
        }
    }

    /// Operator to assign the new state from a block parameter.
    private func assignState(_ newValue: DisclosureState) {
        currentState = newValue
    }

}
