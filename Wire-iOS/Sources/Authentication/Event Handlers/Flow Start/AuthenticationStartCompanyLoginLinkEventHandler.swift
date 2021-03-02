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

import Foundation
import WireSyncEngine

/**
 * Handles the case where the app is opened from an SSO link.
 */

class AuthenticationStartCompanyLoginLinkEventHandler: AuthenticationEventHandler {

    weak var statusProvider: AuthenticationStatusProvider?

    func handleEvent(currentStep: AuthenticationFlowStep, context: (NSError?, Int)) -> [AuthenticationCoordinatorAction]? {
        let error = context.0

        // Only handle "add account" request errors
        guard case .addAccountRequested? = error?.userSessionErrorCode else {
            return nil
        }

        // Only handle this case if there is an SSO code in the error.
        guard let code = error?.userInfo[SessionManager.companyLoginCodeKey] as? UUID else {
            return nil
        }

        if currentStep == .start {
            return [.transition(.landingScreen, mode: .reset), .startCompanyLogin(code: code)]
        } else {
            return [.startCompanyLogin(code: code)]
        }
    }

}
