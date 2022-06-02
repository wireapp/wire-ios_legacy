//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

protocol UnauthenticatedSessionStatusDelegate: AnyObject {

    var isAllowedToCreateNewAccount: Bool { get }

}

class CompanyLoginURLActionProcessor: URLActionProcessor {

    private weak var delegate: UnauthenticatedSessionStatusDelegate?
    private var authenticationStatus: ZMAuthenticationStatus

    init(delegate: UnauthenticatedSessionStatusDelegate, authenticationStatus: ZMAuthenticationStatus) {
        self.delegate = delegate
        self.authenticationStatus = authenticationStatus
    }

    func process(urlAction: URLAction, delegate presentationDelegate: PresentationDelegate?) {
        switch urlAction {
        case .companyLoginSuccess(let userInfo):
            authenticationStatus.loginSucceeded(with: userInfo)
        case .startCompanyLogin(let code):
            guard delegate?.isAllowedToCreateNewAccount == true else {
                presentationDelegate?.failedToPerformAction(urlAction, error: SessionManager.AccountError.accountLimitReached)
                return
            }
            authenticationStatus.notifyCompanyLoginCodeDidBecomeAvailable(code)
        default:
            break
        }

        // Delete the url scheme verification token
        CompanyLoginVerificationToken.flush()

        presentationDelegate?.completedURLAction(urlAction)
    }

}
