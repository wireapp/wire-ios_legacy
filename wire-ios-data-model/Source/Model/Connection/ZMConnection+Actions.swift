//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

public enum ConnectToUserError: Error {
    case unknown
    case noIdentity
    case connectionLimitReached
    case missingLegalholdConsent
    case internalInconsistency
}

public enum UpdateConnectionError: Error {
    case unknown
    case noIdentity
    case notConnected
    case connectionLimitReached
    case missingLegalholdConsent
    case internalInconsistency
}

public struct ConnectToUserAction: EntityAction {

    public typealias Result = Void
    public typealias Failure = ConnectToUserError

    public var resultHandler: ResultHandler?
    public let userID: UUID
    public let domain: String?

    public init(userID: UUID, domain: String?) {
        self.userID = userID
        self.domain = domain
    }
}

public struct UpdateConnectionAction: EntityAction {

    public typealias Result = Void
    public typealias Failure = UpdateConnectionError

    public var resultHandler: ResultHandler?
    public let connectionID: NSManagedObjectID
    public let newStatus: ZMConnectionStatus

    public init(connection: ZMConnection, newStatus: ZMConnectionStatus) {
        self.connectionID = connection.objectID
        self.newStatus = newStatus
    }
}

public extension ZMUser {

    func sendConnectionRequest(to user: UserType, completion: @escaping ConnectToUserAction.ResultHandler) {
        guard
            let userID = user.remoteIdentifier,
            let context = managedObjectContext
        else {
            return completion(.failure(.internalInconsistency))
        }

        var action = ConnectToUserAction(userID: userID, domain: user.domain)
        action.onResult(resultHandler: completion)
        action.send(in: context.notificationContext)
    }

}

public extension ZMConnection {

    func updateStatus(_ status: ZMConnectionStatus, completion: @escaping UpdateConnectionAction.ResultHandler) {
        guard let context = managedObjectContext else {
            return completion(.failure(.internalInconsistency))
        }

        var action = UpdateConnectionAction(connection: self, newStatus: status)
        action.onResult(resultHandler: completion)
        action.send(in: context.notificationContext)
    }

}
