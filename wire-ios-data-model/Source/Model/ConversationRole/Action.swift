//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

@objcMembers
final public class Action: ZMManagedObject {
    public static let nameKey = #keyPath(Action.name)
    public static let roleKey = #keyPath(Action.role)

    @NSManaged public var role: Role
    @NSManaged public var name: String?

    public override static func entityName() -> String {
        return String(describing: Action.self)
    }

    private static func fetchExistingAction(with name: String,
                                            role: Role,
                                            in context: NSManagedObjectContext) -> Action? {
        let fetchRequest = NSFetchRequest<Action>(entityName: self.entityName())
        fetchRequest.predicate = NSPredicate(format: "%K == %@", nameKey, name)

        let actions = context.fetchOrAssert(request: fetchRequest)
        return actions.first(where: {
            role.actions.contains($0)
        })
    }

    @objc
    @discardableResult
    private static func create(managedObjectContext: NSManagedObjectContext,
                               name: String) -> Action {
        let entry = Action.insertNewObject(in: managedObjectContext)
        entry.name = name
        return entry
    }

    @discardableResult
    public static func fetchOrCreate(with name: String,
                                     role: Role,
                                     in context: NSManagedObjectContext, created: inout Bool) -> Action {
        let existingAction = fetchExistingAction(with: name, role: role, in: context)
        let action = existingAction ?? Action.create(managedObjectContext: context, name: name)
        created = (existingAction == nil)
        role.actions.insert(action)
        return action
    }

    public override static func isTrackingLocalModifications() -> Bool {
        return false
    }

}
