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
    func assetCollectionDidFetch(collection: ZMCollection, messages: [MessageCategory: [ZMMessage]], hasMore: Bool) {
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

struct AssetCollectionHolder {
    let conversation: ZMConversation
    let assetCollection: AssetCollection
    let assetCollectionDelegate: AssetCollectionMulticastDelegate
}
