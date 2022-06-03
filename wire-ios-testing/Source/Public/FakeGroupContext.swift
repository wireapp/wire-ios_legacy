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

@objcMembers public class FakeGroupContext: NSObject, ZMSGroupQueue {

    public let dispatchGroup: ZMSDispatchGroup!
    fileprivate let queue: DispatchQueue!
    
    public static var main: FakeGroupContext {
        return FakeGroupContext(queue: DispatchQueue.main, group: ZMSDispatchGroup(label: "FakeGroupContext mainContext"))
    }
    
    public static var sync: FakeGroupContext {
         return FakeGroupContext(queue: DispatchQueue(label: "FakeGroupContext syncContext"), group: ZMSDispatchGroup(label: "FakeSyncContext"))
    }
    
    public init(queue: DispatchQueue, group: ZMSDispatchGroup) {
        self.queue = queue
        self.dispatchGroup = group
    }
    
    public override convenience init() {
        self.init(queue: DispatchQueue(label: "FakeGroupContextPrivateQueue-\(arc4random()%1000)"), group: ZMSDispatchGroup(label: "FakeGroupContext"))
    }
    
    public func performGroupedBlock(_ block: @escaping ()->()) {
        dispatchGroup.async(on: queue, block: block);
    }

}
