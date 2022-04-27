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

/// TODO: rename to MockConversation after objc MockConversation is retired
class SwiftMockConversation: NSObject, Conversation {

	var relatedConnectionState: ZMConnectionStatus = .invalid

	var sortedOtherParticipants: [UserType] = []
	var sortedServiceUsers: [UserType] = []

	func verifyLegalHoldSubjects() {
		// no-op
	}

	var sortedActiveParticipantsUserTypes: [UserType] = []

    var isSelfAnActiveMember: Bool = true

    var conversationType: ZMConversationType = .group

    var teamRemoteIdentifier: UUID?

    var mockLocalParticipantsContain: Bool = false
    func localParticipantsContain(user: UserType) -> Bool {
        return mockLocalParticipantsContain
    }

    var displayName: String = ""

    var connectedUserType: UserType?

    var allowGuests: Bool = false

    var allowServices: Bool = false

    var teamType: TeamType?

    var accessMode: ConversationAccessMode?

    var accessRole: ConversationAccessRole?

    var accessRoles: Set<ConversationAccessRoleV2> = [.teamMember]

    var isUnderLegalHold: Bool = false
    var securityLevel: ZMConversationSecurityLevel = .notSecure

    var mutedMessageTypes: MutedMessageTypes = .none

    var localParticipantsCount: Int = 0
    var lastMessage: ZMConversationMessage?
    var firstUnreadMessage: ZMConversationMessage?

    var areServicesPresent: Bool = false
}

final class MockGroupDetailsConversation: SwiftMockConversation, GroupDetailsConversation {

    var userDefinedName: String?

    var freeParticipantSlots: Int = 1

    var hasReadReceiptsEnabled: Bool = false

    var syncedMessageDestructionTimeout: TimeInterval = 0
}

final class MockInputBarConversationType: SwiftMockConversation, InputBarConversation, TypingStatusProvider {

    var typingUsers: [UserType] = []

    var hasDraftMessage: Bool = false

    var draftMessage: DraftMessage?

    func setIsTyping(_ isTyping: Bool) {
        // no-op
    }

    var isReadOnly: Bool = false

    var participants: [UserType] = []

    var activeMessageDestructionTimeoutValue: MessageDestructionTimeoutValue?
    var hasSyncedMessageDestructionTimeout = false
    var isSelfDeletingMessageSendingDisabled = false
    var isSelfDeletingMessageTimeoutForced = false
}
