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

public protocol EntityNamedProtocol: NSObjectProtocol {
    static var entityName: String { get }
    init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?)
}

extension NSManagedObject {
    public static func insert<A: EntityNamedProtocol>(in context: NSManagedObjectContext) -> A {
        let entity = NSEntityDescription.entity(forEntityName: A.entityName, in: context)!
        let item = A(entity: entity, insertInto: context)
        return item
    }
    
    public static func fetchAll<A: EntityNamedProtocol>(in context: NSManagedObjectContext, withPredicate predicate: NSPredicate? = nil, sortBy sortDescriptors: [NSSortDescriptor] = []) -> [A] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: A.entityName)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        let results = try? context.fetch(fetchRequest)
        let teams = results as? [A]
        return teams ?? []
    }
    
    public static func fetch<A: EntityNamedProtocol>(in context: NSManagedObjectContext, withPredicate predicate: NSPredicate) -> A? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: A.entityName)
        fetchRequest.predicate = predicate
        let results = try? context.fetch(fetchRequest)
        return results?.first as? A
    }

}
