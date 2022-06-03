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

@objcMembers public class DispatchGroupContext : NSObject {
    
    private var isolationQueue = DispatchQueue(label: "context.isolation", attributes: [.concurrent])
    private var _groups : [ZMSDispatchGroup] = []
    
    public var groups : [ZMSDispatchGroup] {
        var groups : [ZMSDispatchGroup] = []
        isolationQueue.sync {
            groups = self._groups
        }
        return groups
    }
    
    
    init(groups: [ZMSDispatchGroup] = []) {
        super.init()
        
        isolationQueue.async(flags: .barrier) {
            self._groups = groups
        }
    }
    
    @objc(addGroup:)
    func add(_ group : ZMSDispatchGroup) {
        isolationQueue.async(flags: .barrier) {
            self._groups.append(group)
        }
    }
    
    @objc(enterAllExcept:)
    func enterAll(except group: ZMSDispatchGroup? = nil) -> [ZMSDispatchGroup] {
        let groups = self.groups.filter { $0 != group}
        
        groups.forEach {
            $0.enter()
        }
        return groups
    }
    
    @objc(leaveGroups:)
    func leave(_ groups : [ZMSDispatchGroup]) {
        groups.forEach { $0.leave() }
    }
        
    func leaveAll() {
        leave(groups)
    }

}
