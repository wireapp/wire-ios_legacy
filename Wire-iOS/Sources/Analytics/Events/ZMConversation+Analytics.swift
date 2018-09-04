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

@objc public enum ConversationType: Int {
    case oneToOne
    case group
}

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
    
    @objc public func analyticsTypeString() -> String? {
        return ConversationType.type(self)?.analyticsTypeString
    }
    
    @objc public class func analyticsTypeString(withConversationType conversationType: ConversationType) -> String {
        return conversationType.analyticsTypeString
    }
    
    /// Whether the conversation is a 1-on-1 conversation with a service user
    @objc public var isOneOnOneServiceUserConversation: Bool {
        guard self.activeParticipants.count == 2,
             let otherUser = self.firstActiveParticipantOtherThanSelf() else {
            return false
        }
        
        return otherUser.serviceIdentifier != nil &&
                otherUser.providerIdentifier != nil
    }
    
    /// Whether the conversation includes at least 1 service user.
    @objc public var includesServiceUser: Bool {
        guard let participants = lastServerSyncedActiveParticipants.array as? [UserType] else { return false }
        return participants.any { $0.isServiceUser }
    }
    
    @objc public var sortedServiceUsers: [UserType] {
        guard let participants = lastServerSyncedActiveParticipants.array as? [UserType] else { return [] }
        return participants.filter { $0.isServiceUser }.sorted { $0.displayName < $1.displayName }
    }
    
    @objc public var sortedOtherParticipants: [UserType] {
        guard let participants = lastServerSyncedActiveParticipants.array as? [UserType] else { return [] }
        return participants.filter { !$0.isServiceUser }.sorted { $0.displayName < $1.displayName }
    }

}

