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

private var zmLog = ZMSLog(tag: "ZMManagedObjectGrouping")

// Describing the generic storage type that contains the data in the format of
// Key => [Value, 
//         Value, 
//         ...]
public protocol TupleKeyArrayType {
    associatedtype Key: Hashable
    associatedtype Value: Any
    var key: Key { get }
    var value: [Value] { get }
}

// Struct to store the pairs of key-value, where value is an array of @c Value.
// Generic struct conforming to @c TupleKeyArrayType.
public struct TupleKeyArray<Key: Hashable, Value: Any>: TupleKeyArrayType {
    public let key: Key
    public let value: [Value]
}

extension Array where Element: TupleKeyArrayType {
    // Merges the array in the format of
    // [[Key_a => [Value_v1_1,
    //             Value_v1_2,
    //             ...]],
    //  [Key_a => [Value_v2_1,
    //             Value_v2_2,
    //             ...]],
    //  [Key_b => [Value_v3_1,
    //             Value_v3_2,
    //             ...]],
    //  ...]
    // (Array containing @c TupleKeyArrayType)
    // To format
    // [Key_a => [Value_v1_1,
    //            Value_v1_2,
    //            ...,
    //            Value_v2_1,
    //            Value_v2_2,
    //            ...],
    //  Key_b => [Value_v3_1,
    //            Value_v3_2,
    //            ...]
    //  ...]
    // (Dictionary from @c Key to array of @c Value)
    public func merge() -> [Element.Key: [Element.Value]] {
        let initialValue: [Element.Key: [Element.Value]] = [:]
        return self.reduce(initialValue) {
            var objectsForKey = $0[$1.key] ?? []
            objectsForKey.append(contentsOf: $1.value)
            var result = $0
            result[$1.key] = objectsForKey
            return result
        }
    }
}

extension NSManagedObjectContext {
    // Locates the entities of type @c T that have the same value for @c keyPath.
    // @param keyPath valid keyPath that can be fetched from the disk store (computed properties are not permitted).
    // @return dictionary containing the pairs of value and array of objects containing the value for @keyPath.
    public func findDuplicated<T: ZMManagedObject, ValueForKey>(by keyPath: String) -> [ValueForKey: [T]] {
        if let storeURL = self.persistentStoreCoordinator?.persistentStores.first?.url,
            !storeURL.isFileURL {
                zmLog.error("findDuplicated<T> does not support in-memory store")
            return [:]
        }

        guard let entity = NSEntityDescription.entity(forEntityName: T.entityName(), in: self),
              let attribute = entity.attributesByName[keyPath] else {
                fatal("Cannot preapare the fetch")
        }

        let keyPathExpression = NSExpression(forKeyPath: keyPath)
        let countExpression = NSExpression(forFunction: "count:", arguments: [keyPathExpression])

        let countExpressionDescription = NSExpressionDescription()
        countExpressionDescription.name = "count"
        countExpressionDescription.expression = countExpression
        countExpressionDescription.expressionResultType = .integer32AttributeType

        let request = NSFetchRequest<NSNumber>()
        request.entity = entity
        request.propertiesToFetch = [attribute, countExpressionDescription]
        request.propertiesToGroupBy = [attribute]
        request.resultType = .dictionaryResultType

        do {
            let distinctIDAndCount = try self.execute(request) as! NSAsynchronousFetchResult<NSDictionary>

            guard let finalResult = distinctIDAndCount.finalResult else {
                return [:]
            }

            let ids = finalResult.filter {
                ($0["count"] as? Int ?? 0) > 1
            }.compactMap {
                $0[keyPath]
            }

            let fetchAllDuplicatesRequest = NSFetchRequest<T>()
            fetchAllDuplicatesRequest.entity = entity
            fetchAllDuplicatesRequest.predicate = NSPredicate(format: "%K IN %@", argumentArray: [keyPath, ids])

            return self.fetchOrAssert(request: fetchAllDuplicatesRequest).group(by: keyPath)

        } catch let error {
            fatal("Cannot perform the fetch: \(error)")
        }
    }
}

extension Array where Element: NSObject {
    // Groups the elements of the array by the equal values in @keyPath.
    // @param keyPath the key path in @c Element to group by.
    // @return dictionary containing the pairs of value and array of objects containing the value for @keyPath.
    public func group<ValueForKey>(by keyPath: String) -> [ValueForKey: [Element]] {
        let tuples: [TupleKeyArray<ValueForKey, Element>?] = self.map {
                guard let valueForKey = $0.value(forKey: keyPath) as? ValueForKey else {
                    return nil
                }
                return TupleKeyArray(key: valueForKey, value: [$0])
            }

        return tuples.compactMap { $0 }.merge()
    }
}
