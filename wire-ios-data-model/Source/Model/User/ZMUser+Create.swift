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

public extension ZMUser {

    /// Fetch an existing user or create a new one if it doesn't already exist.
    ///
    /// - Parameters:
    ///     - remoteIdentifier: UUID assigned to the user.
    ///     - domain: domain assigned to the user.
    ///     - context: `NSManagedObjectContext` on which to fetch or create the user.
    ///                NOTE that this **must** be the sync context.

    @objc static func fetchOrCreate(with remoteIdentifier: UUID,
                                    domain: String?,
                                    in context: NSManagedObjectContext) -> ZMUser {
        var created: Bool = false
        return fetchOrCreate(with: remoteIdentifier, domain: domain, in: context, created: &created)
    }

    /// Fetch an existing user or create a new one if it doesn't already exist.
    ///
    /// - Parameters:
    ///     - remoteIdentifier: UUID assigned to the user.
    ///     - domain: domain assigned to the user.
    ///     - context: `NSManagedObjectContext` on which to fetch or create the user.
    ///                NOTE that this **must** be the sync context.
    ///     - created: Will be set `true` if a new user was created.

    @objc static func fetchOrCreate(with remoteIdentifier: UUID,
                                    domain: String?,
                                    in context: NSManagedObjectContext,
                                    created: UnsafeMutablePointer<Bool>) -> ZMUser {
        // We must only ever call this on the sync context. Otherwise, there's a race condition
        // where the UI and sync contexts could both insert the same user (same UUID) and we'd end up
        // having two duplicates of that user, and we'd have a really hard time recovering from that.
        require(context.zm_isSyncContext, "Users are only allowed to be created on sync context")

        let domain: String? = APIVersion.isFederationEnabled ? domain : nil

        if let user = fetch(with: remoteIdentifier, domain: domain, in: context) {
            return user
        } else {
            created.pointee = true
            let user = ZMUser.insertNewObject(in: context)
            user.remoteIdentifier = remoteIdentifier
            user.domain = domain?.selfOrNilIfEmpty
            return user
        }
    }

}
