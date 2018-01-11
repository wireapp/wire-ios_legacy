//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

extension ZMConversationList {
    func listWithIncomingCalls(_ filter: Bool) -> [ZMConversation] {
        return self.conversations().listWithIncomingCalls(filter)
    }
}

extension Array {
    
    func listWithIncomingCalls(_ filter: Bool) -> [ZMConversation] {
        let ongoingCalls = self.filterIncomingCalls(active: true)
        if ongoingCalls.count > 3 {
            return filter ? [] as [ZMConversation] : self as! [ZMConversation]
        }
        return filter ? ongoingCalls : filterIncomingCalls(active: false)
    }
    
    internal func filterIncomingCalls(active: Bool) -> [ZMConversation] {
        return self.filter({ (obj) -> Bool in
            guard let obj = obj as? ZMConversation else { return false }
            return obj.canJoinCall == active
        }) as? [ZMConversation] ?? []
    }
}
