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


extension ConversationInputBarViewController {
    
    func configureEmojiButton(_ button: IconButton) {
        button.addTarget(self, action: #selector(emojiButtonTapped), for: .touchUpInside)
    }
    
    func emojiButtonTapped(_ sender: IconButton) {
        if mode != .emojiInput {
            mode = .emojiInput
            inputBar.textView.becomeFirstResponder()
        } else {
            emojiKeyboardViewController = nil
            delay(0.3) {
                self.mode = .textInput
            }
        }

        updateEmojiButton(sender)
    }
    
    public func updateEmojiButton(_ button: IconButton) {
        let type = mode == .emojiInput ? ZetaIconType.text : .emoji
        button.setIcon(type, with: .tiny, for: .normal)
    }

    public func createEmojiKeyboardViewController() {
        emojiKeyboardViewController = EmojiKeyboardViewController()
        emojiKeyboardViewController?.delegate = self
    }

}

extension ConversationInputBarViewController: EmojiKeyboardViewControllerDelegate {
    
    func emojiKeyboardViewController(_ viewController: EmojiKeyboardViewController, didSelectEmoji emoji: String) {
        guard mode == .emojiInput else { return }
        let text = inputBar.textView.text ?? ""
        inputBar.textView.text = text + emoji
        textViewDidChange(inputBar.textView)
    }
    
}
