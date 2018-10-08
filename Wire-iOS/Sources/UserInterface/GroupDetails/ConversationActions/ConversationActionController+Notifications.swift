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

enum NotificationResult: CaseIterable {
    case everything, mentions, nothing, cancel
    
    static var title: String {
        return "meta.menu.configure_notification.dialog_message".localized
    }
    
    var mutedMessageTypes: MutedMessageTypes? {
        switch self {
        case .everything:
            return MutedMessageTypes.none
        case .mentions:
            return .nonMentions
        case .nothing:
            return .all
        case .cancel:
            return nil
        }
    }
    
    var title: String {
        return localizationKey.localized
    }
    
    private var localizationKey: String {
        let base = "meta.menu.configure_notification.button_"
        switch self {
        case .everything: return base + "everything"
        case .mentions: return base + "mentions"
        case .nothing: return base + "nothing"
        case .cancel: return base + "cancel"
        }
    }
    
    private var style: UIAlertAction.Style {
        switch self {
        case .cancel: return .cancel
        default: return .default
        }
    }
    
    func action(for conversation: ZMConversation, handler: @escaping (NotificationResult) -> Void) -> UIAlertAction {
        let checkmarkText: String
        
        if let mutedMessageTypes = self.mutedMessageTypes, conversation.mutedMessageTypes == mutedMessageTypes {
            checkmarkText = " ✓"
        }
        else {
            checkmarkText = ""
        }
        
        let title = self.title + checkmarkText
        return .init(title: title, style: style, handler: { _ in handler(self) })
    }
}

extension ConversationActionController {

    func requestNotificationResult(for conversation: ZMConversation, handler: @escaping (NotificationResult) -> Void) {
        let controller = UIAlertController(title: NotificationResult.title, message: nil, preferredStyle: .actionSheet)
        NotificationResult.allCases.map { $0.action(for: conversation, handler: handler) }.forEach(controller.addAction)
        present(controller)
    }

    func handleNotificationResult(_ result: NotificationResult, for conversation: ZMConversation) {
        if let mutedMessageTypes = result.mutedMessageTypes {
            ZMUserSession.shared()?.performChanges {
                conversation.mutedMessageTypes = mutedMessageTypes
            }
        }

    }

}
