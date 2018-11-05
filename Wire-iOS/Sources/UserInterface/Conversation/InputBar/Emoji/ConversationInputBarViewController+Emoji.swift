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
    
    @objc func configureEmojiButton(_ button: IconButton) {
        button.addTarget(self, action: #selector(emojiButtonTapped), for: .touchUpInside)
    }
    
    @objc func emojiButtonTapped(_ sender: IconButton) {
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
    
    @objc public func updateEmojiButton(_ button: IconButton) {
        let type: ZetaIconType
        let color: UIColor
        if mode == .emojiInput {
            type = ZetaIconType.text
            color = UIColor.from(scheme: .iconNormal)
        } else {
            type = ZetaIconType.emoji
            color = UIColor.from(scheme: .iconNormal)
        }

        button.setIconColor(color, for: .normal)
        button.setIcon(type, with: .tiny, for: .normal)
        
    }

    @objc public func createEmojiKeyboardViewController() {
        emojiKeyboardViewController = EmojiKeyboardViewController()
        emojiKeyboardViewController?.delegate = self
        updateBackspaceButton()
    }

}

extension ConversationInputBarViewController: EmojiKeyboardViewControllerDelegate {

    @objc func emojiKeyboardViewControllerDeleteTapped(_ viewController: EmojiKeyboardViewController) {
        inputBar.textView.deleteBackward()
        updateBackspaceButton()
    }
    
    @objc func emojiKeyboardViewController(_ viewController: EmojiKeyboardViewController, didSelectEmoji emoji: String) {
        guard mode == .emojiInput else { return }
        let text = inputBar.textView.text ?? ""
        inputBar.textView.text = text + emoji
        textViewDidChange(inputBar.textView)
        updateBackspaceButton()
    }

    @objc func updateBackspaceButton() {
        emojiKeyboardViewController?.backspaceEnabled = !inputBar.textView.text.isEmpty
    }
    
}
