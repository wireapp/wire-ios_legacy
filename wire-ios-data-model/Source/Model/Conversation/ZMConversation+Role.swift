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

public enum UpdateRoleError: Error {
    case unknown
}

public class UpdateRoleAction: EntityAction {
    public var resultHandler: ResultHandler?

    public typealias Result = Void
    public typealias Failure = UpdateRoleError

    public let userID: NSManagedObjectID
    public let conversationID: NSManagedObjectID
    public let roleID: NSManagedObjectID

    public required init(user: ZMUser, conversation: ZMConversation, role: Role) {
        userID = user.objectID
        conversationID = conversation.objectID
        roleID = role.objectID
    }
}

extension ZMConversation {
    public func updateRole(of participant: UserType,
                           to newRole: Role,
                           completion: @escaping UpdateRoleAction.ResultHandler) {
        guard
            let context = managedObjectContext,
            let user = participant as? ZMUser
        else {
            return completion(.failure(UpdateRoleError.unknown))
        }

        var action = UpdateRoleAction(user: user, conversation: self, role: newRole)
        action.onResult(resultHandler: completion)
        action.send(in: context.notificationContext)
    }
}
