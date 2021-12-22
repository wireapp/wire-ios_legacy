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

/**
 * Handles the change of user data during registration.
 */

class RegistrationIncrementalUserDataChangeHandler: AuthenticationEventHandler {

    weak var statusProvider: AuthenticationStatusProvider?

    func handleEvent(currentStep: AuthenticationFlowStep, context: Void) -> [AuthenticationCoordinatorAction]? {
        // Only handle data change during incremental creation step
        guard case let .incrementalUserCreation(unregisteredUser, _) = currentStep else {
            return nil
        }

        // Check for missing requirements before allowing the user to register.

        if unregisteredUser.marketingConsent == nil {
            return handleMissingMarketingConsent(with: unregisteredUser)

        } else if unregisteredUser.name == nil {
            return requestIntermediateStep(.setName, with: unregisteredUser)

        } else if unregisteredUser.password == nil && unregisteredUser.needsPassword {
            return requestIntermediateStep(.setPassword, with: unregisteredUser)

        } else {
            return handleRegistrationCompletion(with: unregisteredUser)
        }
    }

    // MARK: - Specific Flow Handlers

    private func requestIntermediateStep(_ step: IntermediateRegistrationStep, with user: UnregisteredUser) -> [AuthenticationCoordinatorAction] {
        let flowStep = AuthenticationFlowStep.incrementalUserCreation(user, step)
        return [.hideLoadingView, .transition(flowStep, mode: .reset)]
    }

    private func handleMissingMarketingConsent(with user: UnregisteredUser) -> [AuthenticationCoordinatorAction] {
        // Alert Actions
        let privacyPolicyAction = AuthenticationCoordinatorAlertAction(title: "news_offers.consent.button.privacy_policy.title".localized, coordinatorActions: [.openURL(URL.wr_privacyPolicy.appendingLocaleParameter)])
        let declineAction = AuthenticationCoordinatorAlertAction(title: "general.decline".localized, coordinatorActions: [.setMarketingConsent(false)])
        let acceptAction = AuthenticationCoordinatorAlertAction(title: "general.accept".localized, coordinatorActions: [.setMarketingConsent(true)])

        // Alert
        let alert = AuthenticationCoordinatorAlert(title: "news_offers.consent.title".localized, message: "news_offers.consent.message".localized, actions: [privacyPolicyAction, declineAction, acceptAction])

        return [.hideLoadingView, .presentAlert(alert)]
    }

    private func handleRegistrationCompletion(with user: UnregisteredUser) -> [AuthenticationCoordinatorAction] {
        return [.showLoadingView, .completeUserRegistration]
    }

}
