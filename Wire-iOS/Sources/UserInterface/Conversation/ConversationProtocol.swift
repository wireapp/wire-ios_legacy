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
import WireDataModel


protocol DisplayNameProvider {
    var displayName: String { get }
}

protocol ConnectedUserProvider {
    var connectedUserType: UserType? { get }
}

protocol AllowGuestsProvider {
    var allowGuests: Bool { get }
}

protocol TeamProvider {
    var team: Team? { get }
}

protocol AccessProvider {
    var accessMode: ConversationAccessMode? { get }
    var accessRole: ConversationAccessRole? { get }
}

protocol MessageDestructionTimeoutProvider {
    var messageDestructionTimeout: WireDataModel.MessageDestructionTimeout? { get }
}

// MARK: - Input Bar View controller

protocol InputBarConversation {
    var typingUsers: [UserType] { get }
    var hasDraftMessage: Bool { get }
    var draftMessage: DraftMessage? { get }

    var messageDestructionTimeoutValue: TimeInterval { get }
    var messageDestructionTimeout: MessageDestructionTimeout? { get }

    func setIsTyping(_ isTyping: Bool)

    var isReadOnly: Bool { get }
}

typealias InputBarConversationType = InputBarConversation & ConnectedUserProvider & DisplayNameProvider & ConversationLike

extension ZMConversation: ConnectedUserProvider {
    var connectedUserType: UserType? {
        return connectedUser
    }
}

extension ZMConversation: InputBarConversation {}

// MARK: - GroupDetailsConversation View controllers and child VCs

protocol GroupDetailsConversation {
    var isUnderLegalHold: Bool { get }
    var userDefinedName: String? { get set }

    var securityLevel: ZMConversationSecurityLevel { get }

    var sortedOtherParticipants: [UserType] { get }
    var sortedServiceUsers: [UserType] { get }

    var allowGuests: Bool { get }
    var hasReadReceiptsEnabled: Bool { get }

    var mutedMessageTypes: MutedMessageTypes { get }

    var freeParticipantSlots: Int { get }

    var teamRemoteIdentifier: UUID? { get }
}

typealias GroupDetailsConversationType = GroupDetailsConversation & DisplayNameProvider & AllowGuestsProvider & TeamProvider & AccessProvider & MessageDestructionTimeoutProvider & ConnectedUserProvider & ConversationLike

//TODO: Merge there with ConversationLike
extension ZMConversation: DisplayNameProvider {}
extension ZMConversation: AllowGuestsProvider {}
extension ZMConversation: TeamProvider {}
extension ZMConversation: AccessProvider {}
extension ZMConversation: MessageDestructionTimeoutProvider {}

extension ZMConversation: GroupDetailsConversation {}
