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
import WireDataModel

extension Analytics {
    func guestAttributes(in conversation: ZMConversation) -> [String: Any] {

        let numGuests = conversation.sortedActiveParticipants.filter({
            $0.isGuest(in: conversation)
            }).count

        return [
            "conversation_guests": numGuests.logRound(),
            "user_type": SelfUser.current.isGuest(in: conversation) ? "guest" : "user"
        ]
    }
}

protocol Event {
    var name: String { get }
    var attributes: [AnyHashable: Any]? { get }
}

extension Analytics {

    func tag(_ event: Event) {
        tagEvent(event.name, attributes: event.attributes as? [String: NSObject] ?? [:])
    }

}

enum GuestLinkEvent: Event {
    case created, copied, revoked, shared

    var name: String {
        switch self {
        case .created: return "guest_rooms.link_created"
        case .copied: return "guest_rooms.link_copied"
        case .revoked: return "guest_rooms.link_revoked"
        case .shared: return "guest_rooms.link_shared"
        }
    }

    var attributes: [AnyHashable: Any]? {
        return nil
    }
}

enum GuestRoomEvent: Event {
    case created

    var name: String {
        switch self {
        case .created: return "guest_rooms.guest_room_creation"
        }
    }

    var attributes: [AnyHashable: Any]? {
        return nil
    }
}

extension Event {
    func track() {
        Analytics.shared.tag(self)
    }
}
