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

// MARK: SplitViewController reveal

extension ConversationInputBarViewController {
    func hideLeftView() {
        guard self.isIPadRegularPortrait(device: UIDevice.current, application: UIApplication.shared) else { return }
        guard let splitViewController = wr_splitViewController, splitViewController.isLeftViewControllerRevealed else { return }

        splitViewController.setLeftViewControllerRevealed(false, animated: true)
    }
}

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
            sendText()
            return false
        }
        
        let participants = conversation.activeParticipants.array as! [ZMUser]
        let previousText = textView.text ?? ""
        let currentText = previousText.replacingCharacters(in: Range(range, in: previousText)!, with: text)

        // Enter mentioning flow
        if text == "@" {
            self.mentionsHandler = MentionsHandler(text: currentText, range: range)
        }

        if let handler = mentionsHandler, let searchString = handler.searchString(in: currentText) {
            mentionsView?.search(in: participants, with: searchString)
        } else {
            mentionsHandler = nil
            mentionsView?.dismissIfVisible()
        }

        inputBar.textView.respondToChange(text, inRange: range)
        return true
    }

    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        guard mode != .audioRecord else { return true }
        guard delegate?.responds(to:  #selector(ConversationInputBarViewControllerDelegate.conversationInputBarViewControllerShouldBeginEditing(_:isEditingMessage:))) == true else { return true }

        return delegate?.conversationInputBarViewControllerShouldBeginEditing?(self, isEditingMessage: (nil != editingMessage)) ?? true
    }

    public func textViewDidBeginEditing(_ textView: UITextView) {
        updateAccessoryViews()
        updateNewButtonTitleLabel()
        hideLeftView()
    }

    public func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        guard delegate?.responds(to: #selector(ConversationInputBarViewControllerDelegate.conversationInputBarViewControllerShouldEndEditing(_:))) == true else { return true }

        return delegate?.conversationInputBarViewControllerShouldEndEditing?(self) ?? true
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.count > 0 {
            conversation.setIsTyping(false)
        }
        
        guard let textView = textView as? MarkdownTextView else { preconditionFailure("Invalid textView class") }

        ZMUserSession.shared()?.enqueueChanges {
            let (text, mentions) = textView.preparedText
            self.conversation.draftMessage = DraftMessage(
                text: text,
                mentions: mentions
            )
        }
    }
}

