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

@objc
public protocol LabelType: NSObjectProtocol {

    var remoteIdentifier: UUID? { get }
    var kind: Label.Kind { get }
    var name: String? { get }

}

@objcMembers
public class Label: ZMManagedObject, LabelType {

    @objc
    public enum Kind: Int16 {
        case folder, favorite
    }

    @NSManaged public var name: String?
    @NSManaged public var conversations: Set<ZMConversation>
    @NSManaged public private(set) var markedForDeletion: Bool

    @NSManaged private var remoteIdentifier_data: Data?
    @NSManaged public private(set) var type: Int16

    public override var ignoredKeys: Set<AnyHashable>? {
        var ignoredKeys = super.ignoredKeys

        _ = ignoredKeys?.insert((#keyPath(Label.type)))

        return ignoredKeys
    }

    public var remoteIdentifier: UUID? {
        get {
            guard let data = remoteIdentifier_data else { return nil }
            return UUID(data: data)
        }
        set {
            remoteIdentifier_data = newValue?.uuidData
        }
    }

    public var kind: Kind {
        get {
            return Kind(rawValue: type) ?? .folder
        }
        set {
            type = newValue.rawValue
        }
    }

    public func markForDeletion() {
        markedForDeletion = true
    }

    public override static func entityName() -> String {
        return "Label"
    }

    override public static func sortKey() -> String {
        return #keyPath(Label.name)
    }

    override public static func defaultSortDescriptors() -> [NSSortDescriptor]? {
        return [NSSortDescriptor(key: sortKey(), ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))]
    }

    public override static func predicateForFilteringResults() -> NSPredicate? {
        return NSPredicate(format: "\(#keyPath(Label.type)) == \(Label.Kind.folder.rawValue) AND \(#keyPath(Label.markedForDeletion)) == NO")
    }

    public override static func isTrackingLocalModifications() -> Bool {
        return true
    }

    public static func fetchFavoriteLabel(in context: NSManagedObjectContext) -> Label {
        return fetchOrCreateFavoriteLabel(in: context, create: false)
    }

    @discardableResult
    static func fetchOrCreateFavoriteLabel(in context: NSManagedObjectContext, create: Bool) -> Label {

        // Executing a fetch request is quite expensive, because it will _always_ (1) round trip through
        // (1) the persistent store coordinator and the SQLite engine, and (2) touch the file system.
        // Looping through all objects in the context is way cheaper, because it does not involve (1)
        // taking any locks, nor (2) touching the file system.

        guard let entity = context.persistentStoreCoordinator?.managedObjectModel.entitiesByName[entityName()] else {
            fatal("Label entity not registered in managed object model")
        }

        for managedObject in context.registeredObjects where managedObject.entity == entity && !managedObject.isFault {
            guard let label = managedObject as? Label, label.kind == .favorite else { continue }
            return label

        }

        let fetchRequest = NSFetchRequest<Label>(entityName: Label.entityName())
        fetchRequest.predicate = NSPredicate(format: "type = \(Kind.favorite.rawValue)")
        fetchRequest.fetchLimit = 2

        let results = context.fetchOrAssert(request: fetchRequest)

        require(results.count <= 1, "More than favorite label")

        if let label = results.first {
            return label
        } else if create {
            let label = Label.insertNewObject(in: context)
            label.remoteIdentifier = UUID()
            label.kind = .favorite

            do {
                try context.save()
            } catch {
                fatal("Failure creating favorite label")
            }

            return label
        } else {
            fatal("The favorite label is always expected to exist at all times")
        }
    }

    public static func fetchOrCreate(remoteIdentifier: UUID, create: Bool, in context: NSManagedObjectContext, created: inout Bool) -> Label? {
        if let existing = fetch(with: remoteIdentifier, in: context) {
            created = false
            return existing
        } else if create {
            let label = Label.insertNewObject(in: context)
            label.remoteIdentifier = remoteIdentifier
            created = true
            return label
        }

        return nil
    }

}
