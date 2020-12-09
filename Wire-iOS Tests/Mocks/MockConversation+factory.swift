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

extension MockConversation {
    @objc
    var isSelfAnActiveMember: Bool {
        let selfUserPredicate = NSPredicate(format: "isSelfUser == YES")
        return !sortedActiveParticipants.filter { selfUserPredicate.evaluate(with: $0) }.isEmpty
    }

    @objc
    var localParticipants: Set<AnyHashable> {
        return Set(sortedActiveParticipants as! [AnyHashable])
    }
    
    @objc
    var activeParticipants: [AnyHashable] {
        get {
            return sortedActiveParticipants as! [AnyHashable]
        }
        
        set {
            sortedActiveParticipants = newValue
        }
    }

    static func oneOnOneConversation(otherUser: UserType = MockUser.mockUsers().first!) -> MockConversation {
        let selfUser = (MockUser.mockSelf() as Any) as! ZMUser
        let mockConversation = MockConversation()
        mockConversation.conversationType = .oneOnOne
        mockConversation.displayName = otherUser.name
        mockConversation.connectedUser = otherUser
        mockConversation.sortedActiveParticipants = [selfUser, otherUser]
        mockConversation.isConversationEligibleForVideoCalls = true

        return mockConversation
    }
    
    static func groupConversation(selfUser: UserType = MockUser.mockSelf(),
                                  otherUser: UserType = MockUser.mockUsers().first!) -> MockConversation {
        let mockConversation = MockConversation()
        mockConversation.conversationType = .group
        mockConversation.displayName = otherUser.name
        mockConversation.sortedActiveParticipants = [selfUser, otherUser]
        mockConversation.isConversationEligibleForVideoCalls = true

        return mockConversation
    }
}
