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
import WireRequestStrategy

class AuthenticationStatus: AuthenticationStatusProvider {

    // MARK: - Properties

    let transportSession: ZMTransportSession

    // MARK: - Life cycle

    init(transportSession: ZMTransportSession) {
        self.transportSession = transportSession
    }

    // MARK: - Methods

    var state: AuthenticationState {
        return isLoggedIn ? .authenticated : .unauthenticated
    }

    private var isLoggedIn : Bool {
        return transportSession.cookieStorage.authenticationCookieData != nil
    }

}

extension BackendEnvironmentProvider {
    func cookieStorage(for account: Account) -> ZMPersistentCookieStorage {
        let backendURL = self.backendURL.host!
        return ZMPersistentCookieStorage(forServerName: backendURL, userIdentifier: account.userIdentifier)
    }

    public func isAuthenticated(_ account: Account) -> Bool {
        return cookieStorage(for: account).authenticationCookieData != nil
    }

}
