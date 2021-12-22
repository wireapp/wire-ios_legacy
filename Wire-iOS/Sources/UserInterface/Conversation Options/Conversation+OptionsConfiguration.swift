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

import WireSyncEngine

extension ZMConversation {

    class OptionsConfigurationContainer: NSObject, ConversationOptionsViewModelConfiguration, ZMConversationObserver {

        private var conversation: ZMConversation
        private var token: NSObjectProtocol?
        private let userSession: ZMUserSession
        var allowGuestsChangedHandler: ((Bool) -> Void)?

        init(conversation: ZMConversation, userSession: ZMUserSession) {
            self.conversation = conversation
            self.userSession = userSession
            super.init()
            token = ConversationChangeInfo.add(observer: self, for: conversation)
        }

        var title: String {
            return conversation.displayName.localizedUppercase
        }

        var allowGuests: Bool {
            return conversation.allowGuests
        }

        var isCodeEnabled: Bool {
            return conversation.accessMode?.contains(.code) ?? false
        }

        var areGuestOrServicePresent: Bool {
            return conversation.areGuestsPresent || conversation.areServicesPresent
        }

        func setAllowGuests(_ allowGuests: Bool, completion: @escaping (VoidResult) -> Void) {
            conversation.setAllowGuests(allowGuests, in: userSession) {
                completion($0)
            }
        }

        func conversationDidChange(_ changeInfo: ConversationChangeInfo) {
            guard changeInfo.allowGuestsChanged else { return }
            allowGuestsChangedHandler?(allowGuests)
        }

        func createConversationLink(completion: @escaping (Result<String>) -> Void) {
            conversation.updateAccessAndCreateWirelessLink(in: userSession, completion)
        }

        func fetchConversationLink(completion: @escaping (Result<String?>) -> Void) {
            conversation.fetchWirelessLink(in: userSession, completion)
        }

        func deleteLink(completion: @escaping (VoidResult) -> Void) {
            conversation.deleteWirelessLink(in: userSession, completion)
        }

    }

}
