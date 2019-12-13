//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

enum ActionNames {
    case addConversationMember
    case removeConversationMember
    case modifyConversationName
    case modifyConversationMessageTimer
    case modifyConversationReceiptMode
    case modifyConversationAccess
    case modifyOtherConversationMember
    case leaveConversation
    case deleteConvesation
    
    var name: String {
        switch self {
        case .addConversationMember: return "add_conversation_member"
        case .removeConversationMember: return "remove_conversation_member"
        case .modifyConversationName: return "modify_conversation_name"
        case .modifyConversationMessageTimer: return "modify_conversation_message_timer"
        case .modifyConversationReceiptMode: return "modify_conversation_receipt_mode"
        case .modifyConversationAccess: return "modify_conversation_access"
        case .modifyOtherConversationMember: return "modify_other_conversation_member"
        case .leaveConversation: return "leave_conversation"
        case .deleteConvesation: return "delete_convesation" 
        }
    }
}

extension ZMUser {
    public func canModifyConversationName(of conversation: ZMConversation) -> Bool {
        guard conversation.conversationType == .group else { return true }
        let canModifyConversationName = self.participantRoles.filter({$0.conversation == conversation}).first?.role?.actions.contains(where: {$0.name == ActionNames.modifyConversationName.name})
        return canModifyConversationName ?? false
    }
    
    public func canModifyAccessControl(in conversation: ZMConversation) -> Bool {
        guard conversation.conversationType == .group else { return true }
        let canModifyConversationName = self.participantRoles.filter({$0.conversation == conversation}).first?.role?.actions.contains(where: {$0.name == ActionNames.modifyConversationAccess.name})
        return canModifyConversationName ?? false
    }
    
    public func canModifyMessageTimer(in conversation: ZMConversation) -> Bool {
        guard conversation.conversationType == .group else { return true }
        let canModifyConversationName = self.participantRoles.filter({$0.conversation == conversation}).first?.role?.actions.contains(where: {$0.name == ActionNames.modifyConversationMessageTimer.name})
        return canModifyConversationName ?? false
    }
    
    public func canModifyReceiptMode(in conversation: ZMConversation) -> Bool {
        guard conversation.conversationType == .group else { return true }
        let canModifyConversationName = self.participantRoles.filter({$0.conversation == conversation}).first?.role?.actions.contains(where: {$0.name == ActionNames.modifyConversationReceiptMode.name})
        return canModifyConversationName ?? false
    }
    
    public func canAddMember(to conversation: ZMConversation) -> Bool {
        guard conversation.conversationType == .group else { return true }
        let canModifyConversationName = self.participantRoles.filter({$0.conversation == conversation}).first?.role?.actions.contains(where: {$0.name == ActionNames.addConversationMember.name})
        return canModifyConversationName ?? false
    }
    
    public func canRemoveMember(from conversation: ZMConversation) -> Bool {
        guard conversation.conversationType == .group else { return true }
        let canModifyConversationName = self.participantRoles.filter({$0.conversation == conversation}).first?.role?.actions.contains(where: {$0.name == ActionNames.removeConversationMember.name})
        return canModifyConversationName ?? false
    }
    
    public func canDelete(_ conversation: ZMConversation) -> Bool {
        guard conversation.conversationType == .group else { return true }
        let canModifyConversationName = self.participantRoles.filter({$0.conversation == conversation}).first?.role?.actions.contains(where: {$0.name == ActionNames.deleteConvesation.name})
        return canModifyConversationName ?? false
    }
    
    public func canLeave(_ conversation: ZMConversation) -> Bool {
        guard conversation.conversationType == .group else { return true }
        let canModifyConversationName = self.participantRoles.filter({$0.conversation == conversation}).first?.role?.actions.contains(where: {$0.name == ActionNames.leaveConversation.name})
        return canModifyConversationName ?? false
    }
    
    public func canModifyOtherMember(in conversation: ZMConversation) -> Bool {
        guard conversation.conversationType == .group else { return true }
        let canModifyConversationName = self.participantRoles.filter({$0.conversation == conversation}).first?.role?.actions.contains(where: {$0.name == ActionNames.modifyOtherConversationMember.name})
        return canModifyConversationName ?? false
    }
}

