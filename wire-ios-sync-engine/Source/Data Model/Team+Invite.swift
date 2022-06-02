//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

extension Team {

    /**
     Invite someone to your team via email
     
     - parameters:
         - email: Email address to which invitation will be sent
         - userSession: Session which the invitation should be sent from
         - completion: Handler which will be called on the main thread when the invitation has been sent
     */
    public func invite(email: String, in userSession: ZMUserSession, completion: @escaping InviteCompletionHandler) {
        userSession.syncManagedObjectContext.performGroupedBlock {
            userSession.applicationStatusDirectory?.teamInvitationStatus.invite(email, completionHandler: { [weak userSession] result in
                userSession?.managedObjectContext.performGroupedBlock {
                    completion(result)
                }
            })
        }
    }

}
