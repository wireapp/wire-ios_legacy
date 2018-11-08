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


public extension UIMenuItem {

    @objc(likeItemForMessage:action:)
    class func like(for message: ZMConversationMessage?, with selector: Selector) -> UIMenuItem {
        let titleKey = message?.liked == true ? "content.message.unlike" : "content.message.like"
        return UIMenuItem(title: titleKey.localized, action: selector)
    }

    @objc(saveItemWithAction:)
    class func save(with selector: Selector) -> UIMenuItem {
        return UIMenuItem(title: "content.message.save".localized, action: selector)
    }

    @objc(forwardItemWithAction:)
    class func forward(with selector: Selector) -> UIMenuItem {
        return UIMenuItem(title: "content.message.forward".localized, action: selector)
    }

    @objc(revealItemWithAction:)
    class func reveal(with selector: Selector) -> UIMenuItem {
        return UIMenuItem(title: "content.message.go_to_conversation".localized, action: selector)
    }

    @objc(deleteItemWithAction:)
    class func delete(with selector: Selector) -> UIMenuItem {
        return UIMenuItem(title: "content.message.delete".localized, action: selector)
    }

    @objc(openItemWithAction:)
    class func open(with selector: Selector) -> UIMenuItem {
        return UIMenuItem(title: "content.message.open".localized, action: selector)
    }
    
    @objc(downloadItemWithAction:)
    class func download(with selector: Selector) -> UIMenuItem {
        return UIMenuItem(title: "content.message.download".localized, action: selector)
    }

    @objc(replyToWithAction:)
    class func reply(with selector: Selector) -> UIMenuItem {
        return UIMenuItem(title: "content.message.reply".localized, action: selector)
    }
}
