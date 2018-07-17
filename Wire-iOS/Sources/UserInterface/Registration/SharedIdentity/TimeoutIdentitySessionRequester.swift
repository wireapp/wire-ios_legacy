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

struct SharedIdentitySessionRequesterTimeoutError: LocalizedError {
    let errorDescription: String = "The Single Sign-On provider did not respond to the authentication request. Contact your team administrator for further details."
}

class TimeoutIdentitySessionRequester: SharedIdentitySessionRequester {

    let delay: TimeInterval

    init(delay: TimeInterval) {
        self.delay = delay
    }

    func requestIdentity(for token: UUID, _ completion: @escaping (SharedIdentitySessionResponse) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            completion(.error(SharedIdentitySessionRequesterTimeoutError()))
        }
    }

}
