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

extension ZMConnection {
    @objc(connectionsInManagedObjectContext:)
    class func connections(inManagedObjectContext moc: NSManagedObjectContext) -> [NSFetchRequestResult] {

        let request = sortedFetchRequest()

        let result = moc.fetchOrAssert(request: request)
        return result
    }

    public static func fetchOrCreate(userID: UUID, domain: String?, in context: NSManagedObjectContext) -> ZMConnection {
        guard let connection = fetch(userID: userID, domain: domain, in: context) else {
            return create(userID: userID, domain: domain, in: context)
        }

        return connection
    }

    public static func create(userID: UUID, domain: String?, in context: NSManagedObjectContext) -> ZMConnection {
        require(context.zm_isSyncContext, "Connections are only allowed to be created on sync context")

        let connection = ZMConnection.insertNewObject(in: context)
        connection.to = ZMUser.fetchOrCreate(with: userID, domain: domain, in: context)
        connection.existsOnBackend = true

        return connection
    }

    public static func fetch(userID: UUID,
                             domain: String?,
                             in context: NSManagedObjectContext) -> ZMConnection? {
        let localDomain = ZMUser.selfUser(in: context).domain
        let isSearchingLocalDomain = domain == nil || localDomain == nil || localDomain == domain

        return internalFetch(userID: userID,
                             domain: domain ?? localDomain,
                             searchingLocalDomain: isSearchingLocalDomain,
                             in: context)
    }

    static func internalFetch(userID: UUID,
                              domain: String?,
                              searchingLocalDomain: Bool,
                              in context: NSManagedObjectContext) -> ZMConnection? {

        let predicate: NSPredicate
        if searchingLocalDomain {
            if let domain = domain {
                predicate = NSPredicate(format: "to.remoteIdentifier_data == %@ AND (to.domain == %@ || to.domain == NULL)", userID.uuidData as NSData, domain)
            } else {
                predicate = NSPredicate(format: "to.remoteIdentifier_data == %@", userID.uuidData as NSData)
            }
        } else {
            predicate = NSPredicate(format: "to.remoteIdentifier_data == %@ AND to.domain == %@", userID.uuidData as NSData, domain ?? NSNull.init())
        }

        let fetchRequest = ZMConnection.sortedFetchRequest(with: predicate)
        fetchRequest.fetchLimit = 2 // We only want 1, but want to check if there are too many.
        let result = context.fetchOrAssert(request: fetchRequest)

        require(result.count <= 1, "More than one connection with the same 'to'")

        return result.first as? ZMConnection
    }

}
