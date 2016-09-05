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


extension ConversationType {
    var analyticsAttribute : String {
        switch  self {
        case .OneToOne:     return "one_to_one"
        case .Group:        return "group"
        }
    }
    
    static func type(conversation: ZMConversation) -> ConversationType? {
        switch conversation.conversationType {
        case .OneOnOne:
            return .OneToOne
        case .Group:
            return .Group
        default:
            return nil
        }
    }
}

extension ZMConversation {
    
    public func analyticsAttribute() -> String? {
        return ConversationType.type(self)?.analyticsAttribute
    }
    
    public class func analyticsAttribute(withConversationType conversationType: ConversationType) -> String {
        return conversationType.analyticsAttribute
    }
    
    public var isBotConversation : Bool {
        guard conversationType == .OneOnOne,
              let otherUser = firstActiveParticipantOtherThanSelf() where otherUser.isBot
        else { return false }
        
        return true
    }
}

