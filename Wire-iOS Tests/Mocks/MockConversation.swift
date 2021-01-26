
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
@testable import Wire

class SwiftMockConversation: NSObject, Conversation  {
    var isSelfAnActiveMember: Bool = true
    
    var conversationType: ZMConversationType = .group

    var teamRemoteIdentifier: UUID?
    
    func localParticipantsContain(user: UserType) -> Bool {
        return false
    }
    
    var displayName: String = ""

    var connectedUserType: UserType?
    
    var allowGuests: Bool = false

    var team: Team?
    
    var accessMode: ConversationAccessMode?
    
    var accessRole: ConversationAccessRole?
    
    var messageDestructionTimeout: MessageDestructionTimeout?
}

final class MockGroupDetailsConversation: SwiftMockConversation, GroupDetailsConversation {
    var userDefinedName: String?
        
    var freeParticipantSlots: Int = 1

    var isUnderLegalHold: Bool = false

    var sortedOtherParticipants: [UserType] = []
    var sortedServiceUsers: [UserType] = []

    var securityLevel: ZMConversationSecurityLevel = .notSecure

    var hasReadReceiptsEnabled: Bool = false

    var mutedMessageTypes: MutedMessageTypes = .none
}
