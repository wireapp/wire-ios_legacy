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

extension AuthenticationFlowStep {

    static func makeClientManagementStep(from error: NSError, credentials: ZMCredentials?, statusProvider: AuthenticationStatusProvider?) -> AuthenticationFlowStep? {
        guard let userClientIDs = error.userInfo[ZMClientsKey] as? [NSManagedObjectID] else {
            return nil
        }

        let clients: [UserClient] = userClientIDs.compactMap {
            guard let session = statusProvider?.sharedUserSession else {
                return nil
            }

            guard let object = try? session.managedObjectContext.existingObject(with: $0) else {
                return nil
            }

            return object as? UserClient
        }

        return .clientManagement(clients: clients, credentials: credentials)
    }

}
