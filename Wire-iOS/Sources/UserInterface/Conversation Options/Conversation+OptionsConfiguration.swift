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

extension ZMConversation {
    
    func optionsConfiguration() -> ConversationOptionsViewModelConfiguration {
        return OptionsConfigurationContainer(conversation: self)
    }
    
    class OptionsConfigurationContainer: NSObject, ConversationOptionsViewModelConfiguration, ZMConversationObserver {
        private var conversation: ZMConversation
        private var token: NSObjectProtocol?
        var teamOnlyChangedHandler: ((Bool) -> Void)?
        
        init(conversation: ZMConversation) {
            self.conversation = conversation
            super.init()
            token = ConversationChangeInfo.add(observer: self, for: conversation)
        }
        
        var isTeamOnly: Bool {
            return conversation.accessMode == ConversationAccessMode.teamOnly
        }
        
        func setTeamOnly(_ teamOnly: Bool, completion: @escaping (VoidResult) -> Void) {
            conversation.setAllowGuests(!teamOnly, in: ZMUserSession.shared()!, completion)
        }
        
        func conversationDidChange(_ changeInfo: ConversationChangeInfo) {
            teamOnlyChangedHandler?(isTeamOnly)
        }
    }
    
}
