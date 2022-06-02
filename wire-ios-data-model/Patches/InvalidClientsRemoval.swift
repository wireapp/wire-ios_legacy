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

enum InvalidClientsRemoval {

    /// We had a situation where after merging duplicate users we were not disposing user clients
    /// and this lead to UserClient -> User relationship to be nil. This
    static func removeInvalid(in moc: NSManagedObjectContext) {
        // will skip this during test unless on disk
        do {
            try moc.batchDeleteEntities(named: UserClient.entityName(), matching: NSPredicate(format: "\(ZMUserClientUserKey) == nil"))
        } catch {
            fatalError("Failed to perform batch update: \(error)")
        }
    }
}

