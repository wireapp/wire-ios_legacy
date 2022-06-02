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

extension Sequence where Element: UserType {

    /// Materialize a sequence of UserType into concrete ZMUser instances.
    ///
    /// - parameter context: NSManagedObjectContext on which users should be created.
    ///
    /// - Returns: List of concrete users which could be materialized.

    public func materialize(in context: NSManagedObjectContext) -> [ZMUser] {
        precondition(context.zm_isUserInterfaceContext, "You can only materialize users on the UI context")

        let nonExistingUsers = self.compactMap({ $0 as? ZMSearchUser }).filter({ $0.user == nil })
        nonExistingUsers.createLocalUsers(in: context.zm_sync)

        return self.compactMap({ $0.unbox(in: context) })
    }

}

extension UserType {

    public func materialize(in context: NSManagedObjectContext) -> ZMUser? {
        return [self].materialize(in: context).first
    }

    fileprivate func unbox(in context: NSManagedObjectContext) -> ZMUser? {
        if let user = self as? ZMUser {
            return user
        } else if let searchUser = self as? ZMSearchUser {
            if let user = searchUser.user {
                return user
            } else if let remoteIdentifier = searchUser.remoteIdentifier {
                return ZMUser.fetch(with: remoteIdentifier, domain: searchUser.domain, in: context)
            }
        }

        return nil
    }

}

extension Sequence where Element: ZMSearchUser {

    fileprivate func createLocalUsers(in context: NSManagedObjectContext) {
        let nonExistingUsers = filter({ $0.user == nil }).map { (userID: $0.remoteIdentifier,
                                                                 teamID: $0.teamIdentifier,
                                                                 domain: $0.domain) }

        context.performGroupedBlockAndWait {
            nonExistingUsers.forEach {
                guard let remoteIdentifier = $0.userID else { return }

                let user = ZMUser.fetchOrCreate(with: remoteIdentifier, domain: $0.domain, in: context)
                user.teamIdentifier = $0.teamID
                user.createOrDeleteMembershipIfBelongingToTeam()
            }
            context.saveOrRollback()
        }
    }

}
