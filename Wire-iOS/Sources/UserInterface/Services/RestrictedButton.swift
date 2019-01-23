//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

final class RestrictedButton: Button, Restricted {
    var requiredPermissions: Permissions = [] {
        didSet {
            if shouldHide {
                isHidden = true
            }
        }
    }

    override public var isHidden: Bool {
        get {
            return shouldHide || super.isHidden
        }

        set {
            if shouldHide {
                super.isHidden = true
            } else {
                super.isHidden = newValue
            }
        }
    }
}

extension RestrictedButton {

    static func openServiceConversationButton() -> RestrictedButton {
        return RestrictedButton(style: .full, title: "peoplepicker.services.open_conversation.item".localized)
    }

    static func createAddServiceButton() -> RestrictedButton {
        return RestrictedButton(style: .full, title: "peoplepicker.services.add_service.button".localized)
    }

    static func createServiceConversationButton() -> RestrictedButton {
        return RestrictedButton(style: .full, title: "peoplepicker.services.create_conversation.item".localized)
    }

    static func createDestructiveServiceButton() -> RestrictedButton {
        let button = RestrictedButton(style: .full, title: "participants.services.remove_integration.button".localized)
        button.setBackgroundImageColor(.vividRed, for: .normal)
        return button
    }

    convenience init(style: ButtonStyle, title:String) {
        self.init(style: style)
        setTitle(title, for: .normal)
    }
}
