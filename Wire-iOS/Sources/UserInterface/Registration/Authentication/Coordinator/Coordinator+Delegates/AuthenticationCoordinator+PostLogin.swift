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
import WireSyncEngine

extension AuthenticationCoordinator: PostLoginAuthenticationObserver {

    /// Called when the client is registered.
    func clientRegistrationDidSucceed(accountId: UUID) {
        eventResponderChain.handleEvent(ofType: .clientRegistrationSuccess)
    }

    /// Called when the client failed to register.
    func clientRegistrationDidFail(_ error: NSError, accountId: UUID) {
        eventResponderChain.handleEvent(ofType: .clientRegistrationError(error, accountId))
    }

    /// Called when the access token of the user is invalidated.
    func authenticationInvalidated(_ error: NSError, accountId: UUID) {
        authenticationDidFail(error)
    }

    /// Called when the account was deleted.
    func accountDeleted(accountId: UUID) {
        // no-op
    }

}
