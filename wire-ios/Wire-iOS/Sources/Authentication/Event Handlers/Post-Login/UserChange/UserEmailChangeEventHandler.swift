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
 * Handles the change of email of the user when logging in.
 */

class UserEmailChangeEventHandler: AuthenticationEventHandler {

    weak var statusProvider: AuthenticationStatusProvider?

    func handleEvent(currentStep: AuthenticationFlowStep, context: UserChangeInfo) -> [AuthenticationCoordinatorAction]? {
        let changeInfo = context

        // Only execute actions if the profile has changed.
        guard changeInfo.profileInformationChanged else {
            return nil
        }

        // Only look for email changes in the email link step
        guard case .pendingEmailLinkVerification = currentStep else {
            return nil
        }

        // Verify state
        guard let selfUser = statusProvider?.selfUser else {
            return nil
        }

        guard selfUser.emailAddress?.isEmpty == false else {
            return nil
        }

        // Complete the login flow when the user finished adding email
        return [.hideLoadingView, .completeLoginFlow]
    }

}
