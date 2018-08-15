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

class RegistrationLinearStepCompletionHandler: AuthenticationEventHandler {

    weak var statusProvider: AuthenticationStatusProvider?

    func handleEvent(currentStep: AuthenticationFlowStep, context: RegistrationState) -> [AuthenticationCoordinatorAction]? {
        let registrationState = context
        
        // Check for missing requirements before allowing the user to register.

        if registrationState.acceptedTermsOfService == false {
            return requestIntermediateStep(.reviewTermsOfService, with: registrationState)

        } else if registrationState.marketingConsent == nil {
            return handleMissingMarketingConsent(with: registrationState)

        } else if registrationState.unregisteredUser.name == nil {
            return requestIntermediateStep(.setName, with: registrationState)

        } else if registrationState.unregisteredUser.profileImageData == nil {
            return requestIntermediateStep(.setProfilePicture, with: registrationState)

        } else {
            return handleRegistrationCompletion(with: registrationState)
        }
    }

    // MARK: - Specific Flow Handlers

    private func requestIntermediateStep(_ step: IntermediateRegistrationStep, with state: RegistrationState) -> [AuthenticationCoordinatorAction] {
        let flowStep = AuthenticationFlowStep.linearRegistration(state, step)
        return [.hideLoadingView, .transition(flowStep, resetStack: true)]
    }

    private func handleMissingMarketingConsent(with state: RegistrationState) -> [AuthenticationCoordinatorAction] {

        // Alert Actions

        let privacyPolicyAction = AuthenticationCoordinatorAlertAction(title: "news_offers.consent.button.privacy_policy.title".localized, coordinatorActions: [])

        let declineAction = AuthenticationCoordinatorAlertAction(title: "general.decline".localized, coordinatorActions: [.setMarketingConsent(false)])

        let acceptAction = AuthenticationCoordinatorAlertAction(title: "general.accept".localized, coordinatorActions: [.setMarketingConsent(true)])

        // Alert

        let alert = AuthenticationCoordinatorAlert(title: "news_offers.consent.title".localized, message: "news_offers.consent.message".localized, actions: [privacyPolicyAction, declineAction, acceptAction])

        return [.hideLoadingView, .presentAlert(alert)]
    }

    private func handleRegistrationCompletion(with state: RegistrationState) -> [AuthenticationCoordinatorAction]? {
        return nil
    }

}
