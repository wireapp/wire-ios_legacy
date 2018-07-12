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
import WireSyncEngine

public enum ConversationEvent: Event {

    static let toggleAllowGuestsName = "guest_rooms.allow_guests"

    case toggleAllowGuests(value: Bool)

    var attributes: [AnyHashable : Any]? {
        switch self {
        case let .toggleAllowGuests(value: value):
            return ["is_allow_guests" : value]
        }
    }

    var name: String {
        switch self {
        case .toggleAllowGuests:
            return ConversationEvent.toggleAllowGuestsName
        }
    }
}

extension Analytics {
    public func tagAllowGuests(value: Bool) {
        tag(ConversationEvent.toggleAllowGuests(value: value))
    }
}
