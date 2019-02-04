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
 * Handles the notification informing that the user session has been created after the user registered.
 */

class RegistrationSessionAvailableEventHandler: AuthenticationEventHandler {

    weak var statusProvider: AuthenticationStatusProvider?

    func handleEvent(currentStep: AuthenticationFlowStep, context: Void) -> [AuthenticationCoordinatorAction]? {
        let nextStep: AuthenticationFlowStep?

        // Only handle createUser step
        switch currentStep {
        case .createUser:
            nextStep = nil
        case .teamCreation(.createTeam):
            nextStep = .teamCreation(.inviteMembers)
        default:
            return nil
        }

        // Send the post-registration fields and wait for initial sync
        return [.hideLoadingView, .transition(.pendingInitialSync(next: nextStep), mode: .normal)]
    }

}
