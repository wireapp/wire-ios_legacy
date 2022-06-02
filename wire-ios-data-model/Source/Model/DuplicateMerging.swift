//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

protocol DuplicateMerging {
    associatedtype T: ZMManagedObject
    static func remoteIdentifierDataKey() -> String?
    static func merge(_ items: [T]) -> T?
}

extension DuplicateMerging {
    static func fetchAndMergeDuplicates(with remoteIdentifier: UUID, in moc: NSManagedObjectContext) -> T? {
        let result = fetchAll(with: remoteIdentifier, in: moc)
        let merged = merge(result)
        return merged
    }

    static func fetchAll(with remoteIdentifier: UUID, in moc: NSManagedObjectContext) -> [T] {
        let fetchRequest = NSFetchRequest<T>(entityName: T.entityName())
        let data = (remoteIdentifier as NSUUID).data() as NSData
        fetchRequest.predicate = NSPredicate(format: "%K = %@", remoteIdentifierDataKey()!, data)
        let result = moc.fetchOrAssert(request: fetchRequest)
        return result
    }
}
