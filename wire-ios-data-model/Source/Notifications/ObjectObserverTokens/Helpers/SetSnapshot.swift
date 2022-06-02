//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import WireUtilities

public struct SetStateUpdate<T: Hashable> {

    public let newSnapshot: SetSnapshot<T>
    public let changeInfo: SetChangeInfo<T>

    let removedObjects: Set<T>
    let insertedObjects: Set<T>

}

public protocol SetChangeInfoOwner {
    associatedtype ChangeInfoContent: Hashable
    var orderedSetState: OrderedSetState<ChangeInfoContent> { get }
    var setChangeInfo: SetChangeInfo<ChangeInfoContent> { get }
    var insertedIndexes: IndexSet { get }
    var deletedIndexes: IndexSet { get }
    var deletedObjects: Set<AnyHashable> { get }
    var updatedIndexes: IndexSet { get }
    var movedIndexPairs: [MovedIndex] { get }
    var zm_movedIndexPairs: [ZMMovedIndex] { get }

    func enumerateMovedIndexes(_ block:@escaping (_ from: Int, _ to: Int) -> Void)

}

open class SetChangeInfo<T: Hashable>: NSObject {

    let changeSet: ChangedIndexes<T>
    public let orderedSetState: OrderedSetState<T>

    public let observedObject: NSObject
    open var insertedIndexes: IndexSet { return changeSet.insertedIndexes }
    open var deletedIndexes: IndexSet { return changeSet.deletedIndexes }
    open var deletedObjects: Set<AnyHashable> { return changeSet.deletedObjects }
    open var updatedIndexes: IndexSet { return changeSet.updatedIndexes }
    open var movedIndexPairs: [MovedIndex] { return changeSet.movedIndexes }
    // for temporary objC-compatibility
    open var zm_movedIndexPairs: [ZMMovedIndex] { return changeSet.movedIndexes.map {ZMMovedIndex(from: UInt($0.from), to: UInt($0.to))}}
    convenience init(observedObject: NSObject) {
        let orderSetState = OrderedSetState<T>(array: [])
        self.init(observedObject: observedObject,
                  changeSet: ChangedIndexes(start: orderSetState, end: orderSetState, updated: Set()),
                  orderedSetState: orderSetState)
    }

    public init(observedObject: NSObject, changeSet: ChangedIndexes<T>, orderedSetState: OrderedSetState<T>) {
        self.changeSet = changeSet
        self.orderedSetState = orderedSetState
        self.observedObject = observedObject
    }

    open func enumerateMovedIndexes(_ block:@escaping (_ from: Int, _ to: Int) -> Void) {
        self.changeSet.enumerateMovedIndexes(block: block)
    }

    open override var description: String { return self.debugDescription }
    open override var debugDescription: String {
        return "deleted: \(deletedIndexes), inserted: \(insertedIndexes), " +
        "updated: \(updatedIndexes), moved: \(movedIndexPairs)"
    }

}

public struct SetSnapshot<T: Hashable> {

    public let set: OrderedSetState<T>
    public let moveType: SetChangeMoveType

    public init(set: OrderedSetState<T>, moveType: SetChangeMoveType) {
        self.set = set
        self.moveType = moveType
    }

    // Returns the new state and the notification to send after some changes in messages
    public func updatedState(_ updatedObjects: Set<T>, observedObject: NSObject, newSet: OrderedSetState<T>) -> SetStateUpdate<T>? {

        if self.set == newSet && updatedObjects.count == 0 {
            return nil
        }

        let changeSet = ChangedIndexes(start: self.set, end: newSet, updated: updatedObjects, moveType: self.moveType)
        let changeInfo = SetChangeInfo(observedObject: observedObject, changeSet: changeSet, orderedSetState: newSet)

        if changeInfo.insertedIndexes.count == 0 && changeInfo.deletedIndexes.count == 0 && changeInfo.updatedIndexes.count == 0 && changeInfo.movedIndexPairs.count == 0 {
            return nil
        }
        return SetStateUpdate(newSnapshot: SetSnapshot(set: newSet, moveType: self.moveType),
                              changeInfo: changeInfo,
                              removedObjects: changeSet.deletedObjects,
                              insertedObjects: changeSet.insertedObjects)
    }
}
