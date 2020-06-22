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

import WireDataModel
import WireSyncEngine

let conversationMediaCompleteActionEventName = "contributed"

fileprivate extension ZMConversation {
    var hasSyncedTimeout: Bool {
        if case .synced(_)? = self.messageDestructionTimeout {
            return true
        }
        else {
            return false
        }
    }
}

extension Analytics {

    func tagMediaActionCompleted(_ action: ConversationMediaAction, inConversation conversation: ZMConversation) {
        var attributes = conversation.ephemeralTrackingAttributes
        attributes["action"] = action.attributeValue

        if let typeAttribute = conversation.analyticsTypeString() {
            attributes["with_service"] = conversation.includesServiceUser
            attributes["conversation_type"] = typeAttribute
        }

        attributes["is_global_ephemeral"] = conversation.hasSyncedTimeout
        
        for (key, value) in guestAttributes(in: conversation) {
            attributes[key] = value
        }

        tagEvent(conversationMediaCompleteActionEventName, attributes: attributes)
    }

}
