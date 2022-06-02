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

extension NSOrderedSet {

    public func toOrderedSetState<T: Hashable>() -> OrderedSetState<T> {
        guard let objects = array as? [T] else {
            fatal("Could not cast contents of NSOrderedSet \(type(of: self)) to expected type \(T.self)")
        }
        return OrderedSetState(array: objects)
    }
}

extension Array where Element: Hashable {

    public func toOrderedSetState() -> OrderedSetState<Element> {
        return OrderedSetState(array: self)
    }
}

public struct OrderedSetState<T: Hashable>: Equatable {

    public private(set) var array: [T]
    public private(set) var order: [T: Int]

    public init(array: [T]) {
        guard array.count == Set(array).count else {
            fatalError("Array contains duplicate items")
        }
        var order = [T: Int]()
        for (idx, item) in array.enumerated() {
            order[item] = idx
        }

        self.array = array
        self.order = order
    }

    @discardableResult
    public mutating func move(item: T, to: Int) -> Int? {
        guard let oldIndex = order[item] else { return nil }

        array.remove(at: oldIndex)
        array.insert(item, at: to)
        for i in [oldIndex, to].sorted() {
            order[array[i]] = i
        }
        return oldIndex
    }

    static public func==<T>(lhs: OrderedSetState<T>, rhs: OrderedSetState<T>) -> Bool {
        return lhs.array as [T] == rhs.array as [T]
    }

    public func map<U>(_ transform: (T) throws -> U) rethrows -> [U] {
        return try array.map(transform)
    }
}

public enum SetChangeMoveType {
    case uiTableView, uiCollectionView
}

public struct MovedIndex: Equatable {
    public let from: Int
    public let to: Int

    public static func==(lhs: MovedIndex, rhs: MovedIndex) -> Bool {
        return lhs.from == rhs.from && lhs.to == rhs.to
    }
}

public struct ChangedIndexes<T: Hashable> {

    public let startState: OrderedSetState<T>
    public let endState: OrderedSetState<T>
    public let updatedObjects: Set<T>

    /// deletedIndexes refer to the indexes in the startSet
    public let deletedIndexes: IndexSet

    /// insertedIndexes refer to the indexes after deleting deletedIndexes
    public let insertedIndexes: IndexSet

    /// updatedIndexes refer to the position of the item after the move 
    /// Reloads using these indexes must be performed AFTER inserts / deletes and moves have COMPLETED
    public let updatedIndexes: IndexSet

    /// Depending on the moveType, the `from` index either refers to the position of the item in the original set (uiCollectionView) or to the position in the intermediate set as moves are iteratively applied (uiTableView)
    public let movedIndexes: [MovedIndex]

    public let moveType: SetChangeMoveType

    public let deletedObjects: Set<T>
    public let insertedObjects: Set<T>

    /// Calculates the inserts, deletes, moves and updates comparing two sets of ordered, distinct objects
    /// @param startState: State before the updates
    /// @param endState: State after the updates
    /// @param updatedObjects: Objects that need to be reloaded
    /// @param moveType: depending on viewController, default is uiCollectionView
    public init(start: OrderedSetState<T>, end: OrderedSetState<T>, updated: Set<T>, moveType: SetChangeMoveType = .uiCollectionView) {
        self.startState = start
        self.endState = end
        self.updatedObjects = updated
        self.moveType = moveType

        let result = type(of: self).calculateDeletesInsertsUpdates(start: start, end: end, updated: updated)
        let movedIndexes = type(of: self).calculateMoves(start: start, end: end, afterDeletesAndInserts: result.intermediateState, moveType: moveType)
        self.movedIndexes = movedIndexes

        self.updatedIndexes = result.updatedIndexes
        self.deletedIndexes = IndexSet(result.deletedObjects.values)
        self.insertedIndexes = IndexSet(result.insertedObjects.values.sorted())

        self.deletedObjects = Set(result.deletedObjects.keys)
        self.insertedObjects = Set(result.insertedObjects.keys)
    }

    static func calculateDeletesInsertsUpdates(start: OrderedSetState<T>, end: OrderedSetState<T>, updated: Set<T>)
        -> (insertedObjects: [T: Int], deletedObjects: [T: Int], updatedIndexes: IndexSet, intermediateState: [T]) {
        var updatedIndexes = IndexSet()
        var insertedObjects = end.order
        var deletedObjects = [T: Int]()
        var intermediateState = [T]()

        for (idx, item) in start.array.enumerated() {
            if let newIdx = insertedObjects.removeValue(forKey: item) {
                intermediateState.append(item)
                if updated.contains(item) {
                    updatedIndexes.insert(newIdx)
                }
            } else {
                deletedObjects[item] = idx
            }
        }

        // When iterating through the collection we removed the items we found in the endState from its copy.
        // This way the only items remaining will be inserted objects
        // We need to sort inserted indexes in ascending order to avoid out of bounds inserts
        let ascInsertedIndexes = insertedObjects.values.sorted()
        ascInsertedIndexes.forEach {intermediateState.insert(end.array[$0], at: $0)}

        return (insertedObjects, deletedObjects, updatedIndexes, intermediateState)
    }

    static func calculateMoves(start: OrderedSetState<T>, end: OrderedSetState<T>, afterDeletesAndInserts: [T], moveType: SetChangeMoveType) -> [MovedIndex] {
        var intermediateState = afterDeletesAndInserts
        var movedIndexes = [MovedIndex]()

        if moveType == .uiCollectionView {
            // Moved `from` indexes are referring to the index in the startState
            // Moves must be calculated comparing the endState the immediately updated intermediate state

            // If the intermediate value at the index is different from the endValue:
            // (1) add a move from the index in the startState to the index in endState
            // (2) search for the position of the endValue in the intermediate state, move the item to the current index
            // (3) continue at next index
            for idx in (0..<intermediateState.endIndex) {
                let intermediateValue = intermediateState[idx]
                let endValue = end.array[idx]
                if intermediateValue != endValue {
                    if let oldIdx = start.order[endValue] {
                        movedIndexes.append(MovedIndex(from: oldIdx, to: idx))
                        if let intIdx = intermediateState.firstIndex(of: endValue) {
                            intermediateState.remove(at: intIdx)
                            intermediateState.insert(endValue, at: idx)
                        }
                    }
                }
            }
        }
        else if moveType == .uiTableView {
            // Moved `from` indexes are referring to the index in the intermediate state
            // Moves must be calculated comparing the endState the immediately updated intermediate state

            // If the intermediate value at the index is different from the endValue:
            // (1) search for the position of the endValue in the intermediate state, move the item to the current index
            // (2) add a move from the index in the intermediate state to the index in endState
            // (3) continue at next index

            for idx in (0..<intermediateState.endIndex) {
                let intermediateValue = intermediateState[idx]
                let endValue = end.array[idx]
                if intermediateValue != endValue {
                    if let intIdx = intermediateState.firstIndex(of: endValue) {
                        intermediateState.remove(at: intIdx)
                        intermediateState.insert(endValue, at: idx)
                        movedIndexes.append(MovedIndex(from: intIdx, to: idx))
                    }
                }
            }
        } else {
            fatalError("Unknown moveType \(moveType)")
        }
        return movedIndexes
    }

    public func enumerateMovedIndexes(block: (_ from: Int, _ to: Int) -> Void) {
        for pair in movedIndexes {
            block(Int(pair.from), Int(pair.to))
        }
    }
}
