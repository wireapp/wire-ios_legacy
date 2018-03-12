////
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

extension Analytics {
    @objc public func guestAttributes(in conversation: ZMConversation) -> [String : Any] {
        return [
            "is_allow_guests" : conversation.allowGuests,
            "user_type" : ZMUser.selfUser().isGuest(in: conversation) ? "guest" : "user"
        ]
    }
}

enum GuestLinkEvent: Event {
    case created, copied, revoked, shared
    
    var name: String {
        switch self {
        case .created: return "guests_rooms.link_created"
        case .copied: return "guests_rooms.link_copied"
        case .revoked: return "guests_rooms.link_revoked"
        case .shared: return "guests_rooms.link_shared"
        }
    }
    
    var attributes: [AnyHashable : Any]? {
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
    
    var attributes: [AnyHashable : Any]? {
        return nil
    }
}

extension Event {
    func track() {
        Analytics.shared().tag(self)
    }
}
