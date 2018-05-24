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
    static func oneOnOneConversation() -> MockConversation {
        let selfUser = (MockUser.mockSelf() as Any) as! ZMUser
        let otherUser = MockUser.mockUsers().first!
        let mockConversation = MockConversation()
        mockConversation.conversationType = .oneOnOne
        mockConversation.displayName = otherUser.displayName
        mockConversation.connectedUser = otherUser
        mockConversation.activeParticipants = [selfUser, otherUser]
        mockConversation.isConversationEligibleForVideoCalls = true

        return mockConversation
    }
    
    static func groupConversation() -> MockConversation {
        let selfUser = (MockUser.mockSelf() as Any) as! ZMUser
        let otherUser = MockUser.mockUsers().first!
        let mockConversation = MockConversation()
        mockConversation.conversationType = .group
        mockConversation.displayName = otherUser.displayName
        mockConversation.activeParticipants = [selfUser, otherUser]
        mockConversation.isConversationEligibleForVideoCalls = true

        return mockConversation
    }
}
