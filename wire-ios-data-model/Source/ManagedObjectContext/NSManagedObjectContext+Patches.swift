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

extension NSManagedObjectContext {

    /// Applies the required patches for the current version of the persisted data
    public func applyPersistedDataPatchesForCurrentVersion() {
        PersistedDataPatch.applyAll(in: self)
    }
}

extension NSManagedObjectContext {
    public func batchDeleteEntities(named entityName: String, matching predicate: NSPredicate) throws {
        // will skip this during test unless on disk
        guard self.persistentStoreCoordinator!.persistentStores.first!.type != NSInMemoryStoreType else { return }

        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetch.predicate = predicate
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        request.resultType = .resultTypeObjectIDs
        let result = try self.execute(request) as? NSBatchDeleteResult
        let objectIDArray = result?.result ?? []
        let changes = [NSDeletedObjectsKey: objectIDArray]
        // Deletion happens on persistance layer, we need to notify contexts of the changes manually
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self])
    }
}
