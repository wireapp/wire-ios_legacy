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
        delegate.conversationInputBarViewControllerDidFinishEditingMessage?(editingMessage, withText: text)
        editingMessage = nil
        inputBar.inputBarState = .Writing
    }
    
    func editMessage(message: ZMConversationMessage) {
        guard let text = message.textMessageData?.messageText else { return }
        mode = .TextInput
        editingMessage = message
        inputBar.inputBarState = .Editing(originalText: text)
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(endEditingMessageIfNeeded),
            name: endEditingNotificationName,
            object: nil
        )
    }
    
    func endEditingMessageIfNeeded() {
        guard nil != editingMessage else { return }
        delegate.conversationInputBarViewControllerDidCancelEditingMessage?(editingMessage)
        editingMessage = nil
        inputBar.inputBarState = .Writing
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: endEditingNotificationName,
            object: nil
        )
    }
    
    static func endEditingMessage() {
        NSNotificationCenter.defaultCenter().postNotificationName(endEditingNotificationName, object: nil)
    }

}


extension ConversationInputBarViewController: InputBarEditViewDelegate {

    public func inputBarEditView(editView: InputBarEditView, didTapButtonWithType buttonType: EditButtonType) {
        switch buttonType {
        case .Undo: inputBar.undo()
        case .Cancel: endEditingMessageIfNeeded()
        case .Confirm: sendEditedMessageAndUpdateState(withText: inputBar.textView.text)
        }
    }

}
