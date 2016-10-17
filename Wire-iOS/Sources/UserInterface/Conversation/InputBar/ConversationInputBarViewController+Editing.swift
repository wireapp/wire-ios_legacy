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


private let endEditingNotificationName = "ConversationInputBarViewControllerShouldEndEditingNotification"


extension ConversationInputBarViewController {

    func sendEditedMessageAndUpdateState(withText text: String) {
        delegate.conversationInputBarViewControllerDidFinishEditing?(editingMessage, withText: text)
        editingMessage = nil
        updateWritingState()
    }
    
    func editMessage(_ message: ZMConversationMessage) {
        guard let text = message.textMessageData?.messageText else { return }
        mode = .textInput
        editingMessage = message
        updateRightAccessoryView()

        inputBar.inputBarState = .editing(originalText: text)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(endEditingMessageIfNeeded),
            name: NSNotification.Name(rawValue: endEditingNotificationName),
            object: nil
        )
    }
    
    func endEditingMessageIfNeeded() {
        guard nil != editingMessage else { return }
        delegate.conversationInputBarViewControllerDidCancelEditing?(editingMessage)
        editingMessage = nil
        ZMUserSession.shared().enqueueChanges {
            self.conversation.draftMessageText = ""
        }
        updateWritingState()

        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name(rawValue: endEditingNotificationName),
            object: nil
        )
    }
    
    static func endEditingMessage() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: endEditingNotificationName), object: nil)
    }

    public func updateWritingState() {
        guard nil == editingMessage else { return }
        inputBar.inputBarState = .writing(ephemeral: conversation.destructionEnabled)
        updateRightAccessoryView()
    }

}


extension ConversationInputBarViewController: InputBarEditViewDelegate {

    public func inputBarEditView(_ editView: InputBarEditView, didTapButtonWithType buttonType: EditButtonType) {
        switch buttonType {
        case .undo: inputBar.undo()
        case .cancel: endEditingMessageIfNeeded()
        case .confirm: sendOrEditText(inputBar.textView.text)
        }
    }
    
    public func inputBarEditViewDidLongPressUndoButton(_ editView: InputBarEditView) {
        guard let text = editingMessage?.textMessageData?.messageText else { return }
        inputBar.setInputBarText(text)
    }

}
