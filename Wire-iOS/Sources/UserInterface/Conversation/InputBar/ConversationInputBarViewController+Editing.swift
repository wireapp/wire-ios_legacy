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


private let endEditingNotificationName = "ConversationInputBarViewControllerShouldEndEditingNotification"


extension ConversationInputBarViewController {

    func editMessage(_ message: ZMConversationMessage) {
        guard let text = message.textMessageData?.messageText else { return }
        mode = .textInput
        editingMessage = message
        updateRightAccessoryView()

        inputBar.setInputBarState(.editing(originalText: text, mentions: message.textMessageData?.mentions ?? []), animated: true)
        updateMarkdownButton()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(endEditingMessageIfNeeded),
            name: NSNotification.Name(rawValue: endEditingNotificationName),
            object: nil
        )
    }

    @objc
    func endEditingMessageIfNeeded() {
        guard let message = editingMessage,
              let conversation = conversation as? ZMConversation else { return }

        delegate?.conversationInputBarViewControllerDidCancelEditing(message)
        editingMessage = nil
        ZMUserSession.shared()?.enqueue {
            conversation.draftMessage = nil
        }
        updateWritingState(animated: true)
        conversation.setIsTyping(false)

        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name(rawValue: endEditingNotificationName),
            object: nil
        )
    }

    static func endEditingMessage() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: endEditingNotificationName), object: nil)
    }

    func updateWritingState(animated: Bool) {
        guard nil == editingMessage else { return }
        inputBar.setInputBarState(.writing(ephemeral: ephemeralState), animated: animated)
        updateRightAccessoryView()
        updateMarkdownButton()
    }

}


extension ConversationInputBarViewController: InputBarEditViewDelegate {

    func inputBarEditView(_ editView: InputBarEditView, didTapButtonWithType buttonType: EditButtonType) {
        switch buttonType {
        case .undo: inputBar.undo()
        case .cancel: endEditingMessageIfNeeded()
        case .confirm:
            sendText()
        }
    }

    func inputBarEditViewDidLongPressUndoButton(_ editView: InputBarEditView) {
        guard let text = editingMessage?.textMessageData?.messageText else { return }
        inputBar.setInputBarText(text, mentions: editingMessage?.textMessageData?.mentions ?? [])
    }

}
