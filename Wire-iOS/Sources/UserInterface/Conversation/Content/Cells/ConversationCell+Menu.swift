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

import UIKit

public extension ConversationCell {

    @objc public func showMenu() {
        guard !message.isEphemeral || message.canBeDeleted else { return } // Ephemeral message's only possibility is to be deleted
        let shouldBecomeFirstResponder = delegate?.conversationCellShouldBecomeFirstResponderWhenShowingMenu?(forCell: self) ?? true        
        registerMenuObservers()
        
        //  The reason why we are touching the window here is to workaround a bug where,
        //  After dismissing the webplayer, the window would fail to become the first responder, preventing us to show the menu at all.
        //  We now force the window to be the key window and to be the first responder to ensure that we can show the menu controller.
        window?.makeKey()
        window?.becomeFirstResponder()
        
        if shouldBecomeFirstResponder {
            becomeFirstResponder()
        }
        
        UIMenuController.shared.menuItems = ConversationMessageActionController.allMessageActions
        UIMenuController.shared.setTargetRect(selectionRect, in: selectionView)
        UIMenuController.shared.setMenuVisible(true, animated: true)
    }

    // MARK: - Target / Action

    private func registerMenuObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(menuWillShow), name: UIMenuController.willShowMenuNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(menuDidHide), name: UIMenuController.didHideMenuNotification, object: nil)
    }

    @objc private func menuWillShow(_ note: Notification) {
        showsMenu = true
        setSelectedByMenu(true, animated: true)
        NotificationCenter.default.removeObserver(self, name: UIMenuController.willShowMenuNotification, object: nil)
    }
    
    @objc private func menuDidHide(_ note: Notification) {
        showsMenu = false
        setSelectedByMenu(false, animated: true)
        NotificationCenter.default.removeObserver(self, name: UIMenuController.didHideMenuNotification, object: nil)
    }

    func setSelectedByMenu(_ isSelected: Bool, animated: Bool) {
        let animations = {
            self.selectionView.alpha = isSelected ? ConversationCellSelectedOpacity : 1
        }

        UIView.animate(withDuration: ConversationCellSelectionAnimationDuration, animations: animations)
    }

}
