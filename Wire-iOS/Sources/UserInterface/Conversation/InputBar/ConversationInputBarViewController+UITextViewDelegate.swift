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
            let candidateText = inputBar.textView.preparedText
            sendOrEditText(candidateText, mentions: inputBar.textView.mentions)
            return false
        }

        // Enter mentioning flow
        if text == "@" {
            self.mentionsHandler = MentionsHandler(atSymbolRange: range)
            mentionsView?.searchForUsers(with: "")
        } else if let handler = mentionsHandler, let previousText = textView.text {
            // In mentioning flow
            let currentText = previousText.replacingCharacters(in: Range(range, in: previousText)!, with: text)
            
            if handler.shouldReplaceMention(in: currentText) {
                let searchString = handler.searchString(in: currentText)
                let fetchRequest = ZMUser.sortedFetchRequest(with: ZMUser.predicateForConnectedUsers(withSearch: "@" + searchString))
                let users = (ZMUserSession.shared()?.managedObjectContext.executeFetchRequestOrAssert(fetchRequest) as? [ZMUser]) ?? []
                if let user = users.first {
                    let attachment = MentionTextAttachment(user: user)                    
                    textView.attributedText = handler.replace(mention: attachment, in: textView.attributedText)
                }
                mentionsHandler = nil
                mentionsView?.dismissIfVisible()
            }
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
            self.conversation.draftMessage = DraftMessage(
                text: textView.preparedText,
                mentions: textView.mentions
            )
        }
    }
}

extension ConversationInputBarViewController: MentionsSearchResultsViewControllerDelegate {
    func didSelectUserToMention(_ user: ZMUser) {
        mentionsView?.dismissIfVisible()
        
    }
}
