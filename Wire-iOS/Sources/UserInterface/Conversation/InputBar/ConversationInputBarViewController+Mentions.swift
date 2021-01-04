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
import WireDataModel
import UIKit

extension ConversationInputBarViewController {
    var isInMentionsFlow: Bool {
        return mentionsHandler != nil
    }
    
    var canInsertMention: Bool {
        guard isInMentionsFlow, let mentionsView = mentionsView, mentionsView.users.count > 0 else {
            return false
        }
        return true
    }
    
    func insertBestMatchMention() {
        guard canInsertMention, let mentionsView = mentionsView else {
            fatal("Cannot insert best mention")
        }
        
        if let bestSuggestion = mentionsView.selectedUser {
            insertMention(for: bestSuggestion)
        }
    }
    
    func insertMention(for user: UserType) {
        guard let handler = mentionsHandler else { return }
        
        let text = inputBar.textView.attributedText ?? NSAttributedString(string: inputBar.textView.text)

        let (range, attributedText) = handler.replacement(forMention: user, in: text)

        inputBar.textView.replace(range, withAttributedText: (attributedText && inputBar.textView.typingAttributes))
        playInputHapticFeedback()
        dismissMentionsIfNeeded()
    }
    
    func configureMentionButton() {
        mentionButton.addTarget(self, action: #selector(ConversationInputBarViewController.mentionButtonTapped(sender:)), for: .touchUpInside)
    }

    @objc
    private func mentionButtonTapped(sender: Any) {
        guard !isInMentionsFlow else { return }

        let textView = inputBar.textView
        textView.becomeFirstResponder()

        MentionsHandler.startMentioning(in: textView)
        let position = MentionsHandler.cursorPosition(in: inputBar.textView) ?? 0
        mentionsHandler = MentionsHandler(text: inputBar.textView.text, cursorPosition: position)
    }
}

extension ConversationInputBarViewController: UserSearchResultsViewControllerDelegate {
    func didSelect(user: UserType) {
        insertMention(for: user)
    }
}

extension ConversationInputBarViewController {
    
    func dismissMentionsIfNeeded() {
        mentionsHandler = nil
        mentionsView?.dismiss()
    }

    func triggerMentionsIfNeeded(from textView: UITextView, with selection: UITextRange? = nil) {
        guard let conversation = conversation as? ZMConversation else { return }

        if let position = MentionsHandler.cursorPosition(in: textView, range: selection) {
            mentionsHandler = MentionsHandler(text: textView.text, cursorPosition: position)
        }

        if let handler = mentionsHandler, let searchString = handler.searchString(in: textView.text) {
            let participants = conversation.sortedActiveParticipants
            mentionsView?.users = participants.searchForMentions(withQuery: searchString)
        } else {
            dismissMentionsIfNeeded()
        }
    }

    func registerForTextFieldSelectionChange() {
        guard !ProcessInfo.processInfo.isRunningTests else { return }
        
        textfieldObserverToken = inputBar.textView.observe(\MarkdownTextView.selectedTextRange, options: [.new]) { [weak self] (textView: MarkdownTextView, change: NSKeyValueObservedChange<UITextRange?>) -> Void in
            let newValue = change.newValue ?? nil
            self?.triggerMentionsIfNeeded(from: textView, with: newValue)
        }
    }
}
