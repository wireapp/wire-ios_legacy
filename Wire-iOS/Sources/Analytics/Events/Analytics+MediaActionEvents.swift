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

extension Int {
    //TODO: test
    func logRound(factor: Double = 6) -> Int {
        return Int(ceil(pow(2, (floor(factor * log2(Double(self))) / factor))))
    }
}

extension Analytics {

    func tagMediaActionCompleted(_ action: ConversationMediaAction,
                                 inConversation conversation: ZMConversation) {
        var attributes = conversation.ephemeralTrackingAttributes
        attributes["message_action"] = action.attributeValue

        if let typeAttribute = conversation.analyticsTypeString() {
            attributes["with_service"] = conversation.includesServiceUser
            attributes["conversation_type"] = typeAttribute
        }

        let participants = conversation.sortedActiveParticipants
        
        attributes["is_global_ephemeral"] = conversation.hasSyncedTimeout

        attributes["conversation_size"] = participants.count.logRound()
        attributes["conversation_services"] = conversation.sortedServiceUsers.count.logRound()
        attributes["conversation_guests_wireless"] = participants.filter({
            $0.isWirelessUser && $0.isGuest(in: conversation)
        }).count.logRound()
        
        attributes["conversation_guests_pro"] = participants.filter({
            $0.isGuest(in: conversation) && $0.hasTeam
        }).count.logRound()

        attributes.merge(guestAttributes(in: conversation)) { (_, new) in new }
        
        tagEvent(conversationMediaCompleteActionEventName, attributes: attributes)
    }

}
