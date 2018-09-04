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

public enum LinearGroupCreationFlowEvent {

    static let openedGroupCreationName = "conversation.opened_group_creation"
    static let openedSelectParticipantsName = "conversation.opened_select_participants"
    static let groupCreationSucceededName = "conversation.group_creation_succeeded"
    static let addParticipantsName = "conversation.add_participants"

    public enum Source: String {
        case conversationDetails = "conversation_details"
        case startUI = "start_ui"

        var attributes: [AnyHashable : Any]? {
            return ["method" : self.rawValue]
        }
    }

    case openedGroupCreation(source: Source)
    case openedSelectParticipants(source: Source)
    case groupCreationSucceeded(source: Source, isEmpty: Bool, allowGuests: Bool)
    case addParticipants(source: Source, users: Int, guests: Int, allowGuests: Bool)
}

extension LinearGroupCreationFlowEvent: Event {
    var name: String {
        switch self {
        case .openedGroupCreation:
            return LinearGroupCreationFlowEvent.openedGroupCreationName
        case .openedSelectParticipants:
            return LinearGroupCreationFlowEvent.openedSelectParticipantsName
        case .groupCreationSucceeded:
            return LinearGroupCreationFlowEvent.groupCreationSucceededName
        case .addParticipants:
            return LinearGroupCreationFlowEvent.addParticipantsName
        }
    }

    var attributes: [AnyHashable : Any]? {
        switch self {
        case let .openedGroupCreation(source: source):
            return source.attributes
        case let .openedSelectParticipants(source: source):
            return source.attributes
        case let .groupCreationSucceeded(source: source, isEmpty: isEmpty, allowGuests: allowGuests):
            var attributes = source.attributes
            attributes?["with_participants"] = !isEmpty
            attributes?["is_allow_guests"] = allowGuests
            return attributes
        case let .addParticipants(source: source, users: users, guests: guests, allowGuests: allowGuests):
            var attributes = source.attributes
            attributes?["is_allow_guests"] = allowGuests
            attributes?["user_num"] = users
            attributes?["guest_num"] = guests
            attributes?["temporary_guest_num"] = 0
            return attributes
        }
    }
}


extension Analytics {
    func tagLinearGroupOpened(with source: LinearGroupCreationFlowEvent.Source) {
        tag(LinearGroupCreationFlowEvent.openedGroupCreation(source: source))
    }
    
    func tagLinearGroupSelectParticipantsOpened(with source: LinearGroupCreationFlowEvent.Source) {
        tag(LinearGroupCreationFlowEvent.openedSelectParticipants(source: source))
    }
    
    func tagLinearGroupCreated(with source: LinearGroupCreationFlowEvent.Source, isEmpty: Bool, allowGuests: Bool) {
        tag(LinearGroupCreationFlowEvent.groupCreationSucceeded(source: source, isEmpty: isEmpty, allowGuests: allowGuests))
    }

    public func tagAddParticipants(source: LinearGroupCreationFlowEvent.Source, _ users: Set<ZMUser>, allowGuests: Bool, in conversation: ZMConversation?) {
        let guestsCount: Int
        if ZMUser.selfUser().hasTeam {
            guestsCount = users.filter { !$0.isTeamMember }.count
        } else {
            guestsCount = 0
        }
        let usersCount = users.count - guestsCount
        tag(LinearGroupCreationFlowEvent.addParticipants(source: source, users: usersCount, guests: guestsCount, allowGuests: allowGuests))
    }
}
