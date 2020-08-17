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

extension AuthenticationCoordinator: CompanyLoginControllerDelegate {

    func controller(_ controller: CompanyLoginController, presentAlert alert: UIAlertController) {
        if presenter?.view.window == nil {
            // the alert cannot be presented now, queue it for later
            pendingModal = alert
        } else {
            presenter?.present(alert, animated: true)
        }
    }

    func controller(_ controller: CompanyLoginController, showLoadingView: Bool) {
        presenter?.isLoadingViewVisible = showLoadingView
    }
    
    func controllerDidStartBackendSwitch(_ controller: CompanyLoginController, toURL url: URL) {
        stateController.transition(to: .switchBackend(url: url), mode: .replace)
    }

    func controllerDidStartCompanyLoginFlow(_ controller: CompanyLoginController) {
        stateController.transition(to: .companyLogin)
    }
    
    func controllerDidCancelCompanyLoginFlow(_ controller: CompanyLoginController) {
        cancelCompanyLogin()
    }
}
