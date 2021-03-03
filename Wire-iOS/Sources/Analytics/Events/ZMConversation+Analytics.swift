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
import WireDataModel

enum ConversationType: Int {
    case oneToOne
    case group
}

extension ConversationType {
    var analyticsTypeString: String {
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

    var analyticsTypeString: String? {
        return ConversationType.type(self)?.analyticsTypeString
    }

    /// TODO: move to DM
    /// Whether the conversation is a 1-on-1 conversation with a service user
    var isOneOnOneServiceUserConversation: Bool {
        guard self.localParticipants.count == 2,
             let otherUser = firstActiveParticipantOtherThanSelf else {
            return false
        }

        return otherUser.serviceIdentifier != nil &&
                otherUser.providerIdentifier != nil
    }

    /// TODO: move to DM
    /// Whether the conversation includes at least 1 service user.
    var includesServiceUser: Bool {
        let participants = Array(localParticipants)
        return participants.any { $0.isServiceUser }
    }

    var attributesForConversation: [String: Any] {
        let participants = sortedActiveParticipants

        let attributes: [String: Any] = [
            "conversation_type": analyticsTypeString ?? "invalid",
            "with_service": includesServiceUser ? true : false,
            "is_allow_guests": accessMode == ConversationAccessMode.allowGuests ? true : false,
            "conversation_size": participants.count.logRound(),
            "is_global_ephemeral": hasSyncedTimeout,
            "conversation_services": sortedServiceUsers.count.logRound(),
            "conversation_guests_wireless": participants.filter({
                $0.isWirelessUser && $0.isGuest(in: self)
            }).count.logRound(),
            "conversation_guests_pro": participants.filter({
                $0.isGuest(in: self) && $0.hasTeam
            }).count.logRound()]

        return attributes.updated(other: guestAttributes)
    }

    var hasSyncedTimeout: Bool {
        if case .synced? = messageDestructionTimeout {
            return true
        } else {
            return false
        }
    }

    var guestAttributes: [String: Any] {

        let numGuests = sortedActiveParticipants.filter({
            $0.isGuest(in: self)
        }).count

        return [
            "conversation_guests": numGuests.logRound(),
            "user_type": SelfUser.current.isGuest(in: self) ? "guest" : "user"
        ]
    }
}
