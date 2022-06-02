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

private protocol FederationMigratable: ZMManagedObject {
    static var predicateForObjectsNeedingFederationMigration: NSPredicate? { get }
    var domain: String? { get set }
}

extension ZMConversation: FederationMigratable {
    static let predicateForObjectsNeedingFederationMigration: NSPredicate? = NSPredicate(format: "%K == nil", #keyPath(ZMConversation.domain))
}

extension ZMUser: FederationMigratable {
    static let predicateForObjectsNeedingFederationMigration: NSPredicate? = NSPredicate(format: "%K == nil", #keyPath(ZMUser.domain))
}

extension NSManagedObjectContext {

    public func migrateToFederation() throws {
        try migrateInstancesTowardsFederation(type: ZMUser.self)
        try migrateInstancesTowardsFederation(type: ZMConversation.self)
    }

    private func migrateInstancesTowardsFederation<T: FederationMigratable>(type: T.Type) throws {
        let fetchRequest = NSFetchRequest<T>(entityName: T.entityName())
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.fetchBatchSize = 100
        fetchRequest.predicate = T.predicateForObjectsNeedingFederationMigration

        try fetchRequest.execute().modifyAndSaveInBatches { instance in
            instance.domain = APIVersion.domain
        }
    }
}
