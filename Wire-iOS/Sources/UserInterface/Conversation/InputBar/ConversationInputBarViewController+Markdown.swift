//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
    
    func configureMarkdownButton() {
        
        markdownButton.addTarget(self, action: #selector(markdownButtonTapped), for: .touchUpInside)
        markdownButton.setIcon(.markdownToggle, with: .tiny, for: .normal)
        markdownButton.setIconColor(ColorScheme.default().color(withName: ColorSchemeColorIconNormal), for: .normal)
    }
    
    public func updateMarkdownButton() {
    
        let color: UIColor
        
        if inputBar.isMarkingDown {
            color = ColorScheme.default().color(withName: ColorSchemeColorAccent)
        } else {
            color = ColorScheme.default().color(withName: ColorSchemeColorIconNormal)
        }
        
        markdownButton.setIconColor(color, for: .normal)
        markdownButton.isEnabled = !inputBar.isEditing
    }
    
    func markdownButtonTapped(_ sender: IconButton) {
    
        if !inputBar.isMarkingDown {
            inputBar.textView.becomeFirstResponder()
            inputBar.setInputBarState(.markingDown, animated: true)
        } else {
            inputBar.setInputBarState(.writing(ephemeral: sendButtonState.ephemeral), animated: true)
        }
        
        updateMarkdownButton()
        updateRightAccessoryView()
    }
}
