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

enum LinearGroupCreationFlowEvent: String {
    case openedGroupCreation      = "conversation.opened_group_creation"
    case openedSelectParticipants = "conversation.opened_select_participants"
    case groupCreationSucceeded   = "conversation.group_creation_succeeded"
}

enum LinearGroupCreationFlowSource: String {
    static let key = "method"
    
    case conversationDetails = "conversation_details"
    case startUI = "start_ui"
}

extension Analytics {
    func tagLinearGroupOpened(with method: LinearGroupCreationFlowSource) {
        tagEvent(LinearGroupCreationFlowEvent.openedGroupCreation.rawValue,
                 attributes: [LinearGroupCreationFlowSource.key: method.rawValue])
    }
    
    func tagLinearGroupSelectParticipantsOpened(with method: LinearGroupCreationFlowSource) {
        tagEvent(LinearGroupCreationFlowEvent.openedSelectParticipants.rawValue,
                 attributes: [LinearGroupCreationFlowSource.key: method.rawValue])
    }
    
    func tagLinearGroupCreated(with method: LinearGroupCreationFlowSource, isEmpty: Bool) {
        tagEvent(LinearGroupCreationFlowEvent.groupCreationSucceeded.rawValue,
                 attributes: [LinearGroupCreationFlowSource.key: method.rawValue,
                              "with_participants": !isEmpty])
    }
}
