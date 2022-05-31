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
import UIKit
import WireCommonComponents

extension AuthenticationCoordinator: LandingViewControllerDelegate {

    func landingViewControllerDidChooseLogin() {
        if let fastloginCredentials = AutomationHelper.sharedHelper.automationEmailCredentials {
            let loginRequest = AuthenticationLoginRequest.email(address: fastloginCredentials.email, password: fastloginCredentials.password)
            executeActions([.showLoadingView, .startLoginFlow(loginRequest)])
        } else {
            stateController.transition(to: .provideCredentials(.email, nil))
        }
    }

    func landingViewControllerDidChooseCreateAccount() {
        let unregisteredUser = makeUnregisteredUser()
        stateController.transition(to: .createCredentials(unregisteredUser))
    }

    func landingViewControllerDidChooseEnterpriseLogin() {
        executeActions([.startCompanyLogin(code: nil)])
    }

    func landingViewControllerDidChooseSSOLogin() {
        executeActions([.startSSOFlow])
    }
}
