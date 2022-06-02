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

extension ZMManagedObject {

    @objc public static func fetch(with remoteIdentifier: UUID, in context: NSManagedObjectContext) -> Self? {
        return internalFetch(withRemoteIdentifier: remoteIdentifier, in: context)
    }

    /// Fetch a managed object by its remote identifier
    ///
    /// - parameter remoteIdentifier
    /// - parameter domain: originating domain of the object.
    /// - parameter context: The `NSManagedObjectContext` on which the object will be fetched.
    ///
    /// If the domain is nil only objects belonging to your own domain will be returned. Similarily if the self user aren't associated with a domain the domain parameter will be ignored.
    @objc public static func fetch(with remoteIdentifier: UUID, domain: String?, in context: NSManagedObjectContext) -> Self? {
        let domain: String? = APIVersion.isFederationEnabled ? domain?.selfOrNilIfEmpty : nil
        let localDomain = ZMUser.selfUser(in: context).domain
        let isSearchingLocalDomain = domain == nil || localDomain == nil || localDomain == domain

        return internalFetch(withRemoteIdentifier: remoteIdentifier,
                             domain: domain ?? localDomain,
                             searchingLocalDomain: isSearchingLocalDomain,
                             in: context)
    }

}

public extension ZMManagedObject {

    static func existingObject(for id: NSManagedObjectID, in context: NSManagedObjectContext) -> Self? {
        return try? context.existingObject(with: id) as? Self
    }

}

public extension Collection where Element == NSManagedObjectID {

    func existingObjects<T: ZMManagedObject>(in context: NSManagedObjectContext) -> [T]? {
        let objects = compactMap({ T.existingObject(for: $0, in: context) })
        return objects.count == self.count ? objects : nil
    }
}
