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
        let shouldBecomeFirstResponder = delegate.conversationCell?(self, shouldBecomeFirstResponderWhenShowMenuWithCellType: messageType()) ?? true
        
        guard let properties = menuConfigurationProperties() else { return }
        registerMenuObservers()
        
        //  The reason why we are touching the window here is to workaround a bug where,
        //  After dismissing the webplayer, the window would fail to become the first responder, preventing us to show the menu at all.
        //  We now force the window to be the key window and to be the first responder to ensure that we can show the menu controller.
        window?.makeKey()
        window?.becomeFirstResponder()
        
        if shouldBecomeFirstResponder {
            becomeFirstResponder()
        }
        
        UIMenuController.shared.menuItems = ConversationCell.items(for: message, with: properties)
        UIMenuController.shared.setTargetRect(properties.targetRect, in: properties.targetView)
        UIMenuController.shared.setMenuVisible(true, animated: true)
        
        delegate?.conversationCell?(self, didOpenMenuForCellType: messageType())
    }
    
    // MARK: - Helper
    
    private func registerMenuObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(menuWillShow), name: .UIMenuControllerWillShowMenu, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(menuDidHide), name: .UIMenuControllerDidHideMenu, object: nil)
    }
    
    private static func items(for message: ZMConversationMessage, with properties: MenuConfigurationProperties) -> [UIMenuItem] {
        var items = [UIMenuItem]()
        
        if message.isEphemeral {
            items += properties.additionalItems.filter(\.isAvailableInEphemeralConversations).map(\.item)
        } else {
            items += properties.additionalItems.map(\.item)
            
            if message.canBeLiked {
                let index = items.count > 0 ? properties.likeItemIndex : 0
                items.insert(.like(for: message, with: #selector(likeMessage)), at: index)
            }
        }
        
        if message.canBeDeleted {
            items.append(.delete(with: #selector(deleteMessage)))
        }
        
        return items
    }
    
    // MARK: - Target / Action
    
    @objc private func menuWillShow(_ note: Notification) {
        showsMenu = true
        menuConfigurationProperties().selectedMenuBlock?(true, true)
        NotificationCenter.default.removeObserver(self, name: .UIMenuControllerWillShowMenu, object: nil)
    }
    
    @objc private func menuDidHide(_ note: Notification) {
        showsMenu = false
        menuConfigurationProperties().selectedMenuBlock?(false, true)
        NotificationCenter.default.removeObserver(self, name: .UIMenuControllerDidHideMenu, object: nil)
    }
    
    @objc private func deleteMessage(_ sender: Any) {
        beingEdited = true
        delegate?.conversationCell?(self, didSelect: .delete)
    }

}
