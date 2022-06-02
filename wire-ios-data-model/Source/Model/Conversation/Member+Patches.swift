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

extension Member {

    // Model version 2.39.0 adds a `remoteIdentifier` attribute to the `Member` entity.
    // The value should be the same as the `remoteIdentifier` of the members user.
    static func migrateRemoteIdentifiers(in context: NSManagedObjectContext) {
        let request = NSFetchRequest<Member>(entityName: Member.entityName())
        context.fetchOrAssert(request: request).forEach(migrateUserRemoteIdentifer)
    }

    static private func migrateUserRemoteIdentifer(for member: Member) {
        member.remoteIdentifier = member.user?.remoteIdentifier
    }

}
