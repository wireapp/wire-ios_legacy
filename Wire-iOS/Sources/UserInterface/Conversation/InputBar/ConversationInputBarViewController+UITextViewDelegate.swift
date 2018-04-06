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

import Foundation
extension ConversationInputBarViewController: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        // In case the conversation isDeleted
        if conversation.managedObjectContext == nil {
            return
        }

        conversation.setIsTyping(textView.text.count > 0)

        updateRightAccessoryView()
    }

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // send only if send key pressed
        if textView.returnKeyType == .send && (text == "\n") {
            inputBar.textView.autocorrectLastWord()
            let candidateText = inputBar.textView.preparedText
            sendOrEditText(candidateText)
            return false
        }

        inputBar.textView.respondToChange(text, inRange: range)
        return true
    }

    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        guard mode != .audioRecord else { return true }
        guard delegate.responds(to:  #selector(ConversationInputBarViewControllerDelegate.conversationInputBarViewControllerShouldBeginEditing(_:isEditingMessage:))) else { return true }
        
        return delegate.conversationInputBarViewControllerShouldBeginEditing!(self, isEditingMessage: (nil != editingMessage))
    }

    public func textViewDidBeginEditing(_ textView: UITextView) {
        updateAccessoryViews()
        updateNewButtonTitleLabel()
        AppDelegate.checkNetwork()
        if UIDevice.current.userInterfaceIdiom == .pad {
            ///TODO: dismiss left view
        }
    }

    public func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        if delegate.responds(to: #selector(ConversationInputBarViewControllerDelegate.conversationInputBarViewControllerShouldEndEditing(_:))) {
            return delegate.conversationInputBarViewControllerShouldEndEditing!(self)
        }
        return true
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.count > 0 {
            conversation.setIsTyping(false)
        }
        ZMUserSession.shared()?.enqueueChanges({() -> Void in
            self.conversation.draftMessageText = textView.text
        })
    }
}

