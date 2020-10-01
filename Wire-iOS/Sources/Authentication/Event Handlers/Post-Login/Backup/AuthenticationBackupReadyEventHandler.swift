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
import WireCommonComponents
import WireSyncEngine

/**
 * Handles the notification informing the user that backups are ready to be imported.
 */

final class AuthenticationBackupReadyEventHandler: AuthenticationEventHandler {

    weak var statusProvider: AuthenticationStatusProvider?

    func handleEvent(currentStep: AuthenticationFlowStep, context: Bool) -> [AuthenticationCoordinatorAction]? {
        let existingAccount = context

        // Automatically complete the backup for @fastLogin automation
        guard AutomationHelper.sharedHelper.automationEmailCredentials == nil else {
            return [.showLoadingView, .configureNotifications, .completeBackupStep]
        }

        // Get the signed-in user credentials
        let authenticationCredentials: ZMCredentials?

        switch currentStep {
        case .authenticateEmailCredentials(let credentials):
            authenticationCredentials = credentials
        case .authenticatePhoneCredentials(let credentials):
            authenticationCredentials = credentials
        case .companyLogin:
            authenticationCredentials = nil
        case .noHistory:
            return [.hideLoadingView]
        default:
            return nil
        }

        // Prepare the backup step
        let context: NoHistoryContext = existingAccount ? .loggedOut : .newDevice
        let nextStep = AuthenticationFlowStep.noHistory(credentials: authenticationCredentials, context: context)

        return [.hideLoadingView, .transition(nextStep, mode: .reset)]
    }

}
