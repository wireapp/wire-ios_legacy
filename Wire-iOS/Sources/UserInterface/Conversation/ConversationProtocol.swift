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
import WireSyncEngine

/// from UI project, to randomize users display in avatar icon
protocol StableRandomParticipantsProvider {
    var stableRandomParticipants: [UserType] { get }
}

protocol ConversationStatusProvider {
    var status: ConversationStatus { get }
}

protocol ConnectedUserProvider {
    var connectedUserType: UserType? { get }
}

// MARK: - ZMConversation extension from sync engine
protocol TypingStatusProvider {
    var typingUsers: [UserType] { get }
    func setIsTyping(_ isTyping: Bool)
}

protocol VoiceChannelProvider {
    var voiceChannel: VoiceChannel? { get }
}
// MARK: - Input Bar View controller

protocol InputBarConversation {
    var typingUsers: [UserType] { get }
    var hasDraftMessage: Bool { get }
    var draftMessage: DraftMessage? { get }

    var messageDestructionTimeoutValue: TimeInterval { get }
    var messageDestructionTimeout: MessageDestructionTimeout? { get }


    var isReadOnly: Bool { get }
}

typealias InputBarConversationType = InputBarConversation & TypingStatusProvider & ConversationLike

extension ZMConversation: InputBarConversation {}

// MARK: - GroupDetailsConversation View controllers and child VCs

protocol GroupDetailsConversation {
    var userDefinedName: String? { get set }

    var sortedServiceUsers: [UserType] { get }

    var allowGuests: Bool { get }
    var hasReadReceiptsEnabled: Bool { get }


    var freeParticipantSlots: Int { get }

    var teamRemoteIdentifier: UUID? { get }
}

typealias GroupDetailsConversationType = GroupDetailsConversation & Conversation

extension ZMConversation: ConversationStatusProvider {}

extension ZMConversation: TypingStatusProvider {}
extension ZMConversation: VoiceChannelProvider {}

extension ZMConversation: GroupDetailsConversation {}

