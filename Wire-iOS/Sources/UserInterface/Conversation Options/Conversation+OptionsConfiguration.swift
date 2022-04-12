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

enum GuestLinkFeatureStatus {
    case enabled
    case disabled
    case unknown
}

extension ZMConversation {
    class OptionsConfigurationContainer: NSObject, ConversationGuestOptionsViewModelConfiguration, ConversationServicesOptionsViewModelConfiguration, ZMConversationObserver {

        private var conversation: ZMConversation
        private var token: NSObjectProtocol?
        private let userSession: ZMUserSession
        var allowGuestsChangedHandler: ((Bool) -> Void)?
        var allowServicesChangedHandler: ((Bool) -> Void)?
        var guestLinkFeatureStatusChangedHandler: ((GuestLinkFeatureStatus) -> Void)?

        init(conversation: ZMConversation, userSession: ZMUserSession) {
            self.conversation = conversation
            self.userSession = userSession
            super.init()
            token = ConversationChangeInfo.add(observer: self, for: conversation)

            conversation.canGenerateGuestLink(in: userSession) { [weak self] result in
                switch result {
                case .success(true):
                    self?.guestLinkFeatureStatus = .enabled
                case .success(false):
                    self?.guestLinkFeatureStatus = .disabled
                case .failure:
                    self?.guestLinkFeatureStatus = .unknown
                @unknown default:
                    self?.guestLinkFeatureStatus = .unknown
                }
            }

        }

        var isConversationFromSelfTeam: Bool {
            let selfUser = ZMUser.selfUser(inUserSession: userSession)

            return conversation.teamRemoteIdentifier == selfUser.teamIdentifier
        }

        var title: String {
            return conversation.displayName.localizedUppercase
        }

        var allowGuests: Bool {
            return conversation.allowGuests
        }

        var allowServices: Bool {
            return conversation.allowServices
        }

        var guestLinkFeatureStatus: GuestLinkFeatureStatus = .unknown {
            didSet {
                guestLinkFeatureStatusChangedHandler?(guestLinkFeatureStatus)
            }
        }

        var isCodeEnabled: Bool {
            return conversation.accessMode?.contains(.code) ?? false
        }

        var areGuestPresent: Bool {
            return conversation.areGuestsPresent
        }

        var areServicePresent: Bool {
            return conversation.areServicesPresent
        }

        func setAllowGuests(_ allowGuests: Bool, completion: @escaping (VoidResult) -> Void) {
            conversation.setAllowGuests(allowGuests, in: userSession) {
                completion($0)
            }
        }

        func setAllowServices(_ allowServices: Bool, completion: @escaping (VoidResult) -> Void) {
            conversation.setAllowServices(allowServices, in: userSession) {
                completion($0)
            }
        }

        func conversationDidChange(_ changeInfo: ConversationChangeInfo) {

            if changeInfo.allowGuestsChanged {
                allowGuestsChangedHandler?(allowGuests)
            }

            if changeInfo.allowServicesChanged {
                allowServicesChangedHandler?(allowServices)
            }
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
