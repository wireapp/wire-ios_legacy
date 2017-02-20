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


open class MulticastDelegate<T: Any>: NSObject {
    private let delegates = NSHashTable<AnyObject>(options: .weakMemory, capacity: 0)
    
    func add(_ delegate: T) {
        delegates.add(delegate as AnyObject)
    }
    
    func remove(_ delegate: T) {
        delegates.remove(delegate as AnyObject)
    }
    
    func call(_ function:@escaping (T)->()) {
        delegates.allObjects.forEach {
            function($0 as! T)
        }
    }
}

final class AssetCollectionMulticastDelegate: MulticastDelegate<AssetCollectionDelegate> {
}

extension AssetCollectionMulticastDelegate: AssetCollectionDelegate {
    public func assetCollectionDidFetch(collection: ZMCollection, messages: [CategoryMatch : [ZMConversationMessage]], hasMore: Bool) {
        self.call {
            $0.assetCollectionDidFetch(collection: collection, messages: messages, hasMore: hasMore)
        }
    }
    
    func assetCollectionDidFinishFetching(collection: ZMCollection, result : AssetFetchResult) {
        self.call {
            $0.assetCollectionDidFinishFetching(collection: collection, result: result)
        }
    }
}

final class AssetCollectionWrapper: NSObject {
    let conversation: ZMConversation
    let assetCollection: ZMCollection
    let assetCollectionDelegate: AssetCollectionMulticastDelegate
    let matchingCategories: [CategoryMatch]
    
    init(conversation: ZMConversation, assetCollection: ZMCollection, assetCollectionDelegate: AssetCollectionMulticastDelegate, matchingCategories: [CategoryMatch]) {
        self.conversation = conversation
        self.assetCollection = assetCollection
        self.assetCollectionDelegate = assetCollectionDelegate
        self.matchingCategories = matchingCategories
    }
    
    convenience init(conversation: ZMConversation, matchingCategories: [CategoryMatch]) {
        let assetCollection: ZMCollection
        let delegate = AssetCollectionMulticastDelegate()
        if Settings.shared().enableBatchCollections {
            assetCollection = AssetCollectionBatched(conversation: conversation, matchingCategories: matchingCategories, delegate: delegate)
        }
        else {
            assetCollection = AssetCollection(conversation: conversation, matchingCategories: matchingCategories, delegate: delegate)
        }
        self.init(conversation: conversation, assetCollection: assetCollection, assetCollectionDelegate: delegate, matchingCategories: matchingCategories)
    }
    
    deinit {
        assetCollection.tearDown()
    }
}
