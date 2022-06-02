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
import WireSystem

private var zmLog = ZMSLog(tag: "ConversationListObserverCenter")

extension ZMConversationList {

    func toOrderedSetState() -> OrderedSetState<ZMConversation> {
        return OrderedSetState(array: self.map {$0 as! ZMConversation})
    }

}

@objcMembers public final class ConversationListChangeInfo: NSObject, SetChangeInfoOwner {
    public typealias ChangeInfoContent = ZMConversation
    public var setChangeInfo: SetChangeInfo<ZMConversation>

    public var conversationList: ZMConversationList { return setChangeInfo.observedObject as! ZMConversationList }

    init(setChangeInfo: SetChangeInfo<ZMConversation>) {
        self.setChangeInfo = setChangeInfo
    }

    public var orderedSetState: OrderedSetState<ChangeInfoContent> { return setChangeInfo.orderedSetState }
    public var insertedIndexes: IndexSet { return setChangeInfo.insertedIndexes }
    public var deletedIndexes: IndexSet { return setChangeInfo.deletedIndexes }
    public var deletedObjects: Set<AnyHashable> { return setChangeInfo.deletedObjects }
    public var updatedIndexes: IndexSet { return setChangeInfo.updatedIndexes }
    public var movedIndexPairs: [MovedIndex] { return setChangeInfo.movedIndexPairs }
    public var zm_movedIndexPairs: [ZMMovedIndex] { return setChangeInfo.zm_movedIndexPairs}
    public func enumerateMovedIndexes(_ block:@escaping (_ from: Int, _ to: Int) -> Void) {
        setChangeInfo.enumerateMovedIndexes(block)
    }
}

@objc public protocol ZMConversationListObserver: NSObjectProtocol {
    func conversationListDidChange(_ changeInfo: ConversationListChangeInfo)
    @objc optional func conversationInsideList(_ list: ZMConversationList, didChange changeInfo: ConversationChangeInfo)
}

@objc public protocol ZMConversationListReloadObserver: NSObjectProtocol {
    func conversationListsDidReload()
}

@objc public protocol ZMConversationListFolderObserver: NSObjectProtocol {
    func conversationListsDidChangeFolders()
}

extension ConversationListChangeInfo {

    /// Adds a ZMConversationListObserver to the specified list
    /// You must hold on to the token and use it to unregister
    @objc(addObserver:forList:managedObjectContext:)
    public static func addListObserver(_ observer: ZMConversationListObserver, for list: ZMConversationList?, managedObjectContext: NSManagedObjectContext) -> NSObjectProtocol {

        if let list = list {
            zmLog.debug("Registering observer \(observer) for list \(list.identifier)")
        } else {
            zmLog.debug("Registering observer \(observer) for all lists")
        }

        return ManagedObjectObserverToken(name: .conversationListDidChange, managedObjectContext: managedObjectContext, object: list) { [weak observer] (note) in
            guard let `observer` = observer, let aList = note.object as? ZMConversationList else { return }

            zmLog.debug("Notifying registered observer \(observer) about changes in list: \(aList.identifier)")

            if let changeInfo = note.userInfo["conversationListChangeInfo"] as? ConversationListChangeInfo {
                observer.conversationListDidChange(changeInfo)
            }
            if let changeInfos = note.userInfo["conversationChangeInfos"] as? [ConversationChangeInfo] {
                changeInfos.forEach {
                    observer.conversationInsideList?(aList, didChange: $0)
                }
            }
        }
    }

    @objc(addConversationListReloadObserver:managedObjectcontext:)
    public static func addReloadObserver(_ observer: ZMConversationListReloadObserver, managedObjectContext: NSManagedObjectContext) -> NSObjectProtocol {
        return ManagedObjectObserverToken(name: .conversationListsDidReload, managedObjectContext: managedObjectContext, block: { [weak observer] _ in
            observer?.conversationListsDidReload()
        })
    }

    @objc(addConversationListFolderObserver:managedObjectcontext:)
    public static func addFolderObserver(_ observer: ZMConversationListFolderObserver, managedObjectContext: NSManagedObjectContext) -> NSObjectProtocol {
        return ManagedObjectObserverToken(name: .conversationListDidChangeFolders, managedObjectContext: managedObjectContext, block: { [weak observer] _ in
            observer?.conversationListsDidChangeFolders()
        })
    }
}
