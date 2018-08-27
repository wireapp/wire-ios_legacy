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

/**
 * Handles changes in the team creation state.
 */

class TeamCreationAdvancementEventHandler: AuthenticationEventHandler {

    weak var statusProvider: AuthenticationStatusProvider?

    func handleEvent(currentStep: AuthenticationFlowStep, context: String) -> [AuthenticationCoordinatorAction]? {
        // Only handle events during team creation
        guard case let .teamCreation(state) = currentStep else {
            return nil
        }

        guard let nextState = state.nextState(with: context) else {
            return nil
        }

        switch nextState {
        case .createTeam:
            return [.showLoadingView]
        case .setFullName:
            let alert = AuthenticationCoordinatorAlert.makeMarketingConsentAlert()
            return [.hideLoadingView, .presentAlert(alert), .transition(.teamCreation(nextState), resetStack: false)]
        default:
            return [.hideLoadingView, .transition(.teamCreation(nextState), resetStack: false)]
        }
    }

}
