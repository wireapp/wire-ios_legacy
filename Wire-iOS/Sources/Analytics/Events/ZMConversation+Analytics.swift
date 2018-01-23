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
    var analyticsTypeString : String {
        switch  self {
        case .oneToOne:     return "one_to_one"
        case .group:        return "group"
        }
    }
    
    static func type(_ conversation: ZMConversation) -> ConversationType? {
        switch conversation.conversationType {
        case .oneOnOne:
            return .oneToOne
        case .group:
            return .group
        default:
            return nil
        }
    }
}

extension ZMConversation {
    
    public func analyticsTypeString() -> String? {
        return ConversationType.type(self)?.analyticsTypeString
    }
    
    public class func analyticsTypeString(withConversationType conversationType: ConversationType) -> String {
        return conversationType.analyticsTypeString
    }
    
    public var isServiceUserConversation : Bool {
        guard self.activeParticipants.count == 2,
             let otherUser = self.firstActiveParticipantOtherThanSelf() else {
            return false
        }
        
        return otherUser.serviceIdentifier != nil &&
                otherUser.providerIdentifier != nil
    }
}

