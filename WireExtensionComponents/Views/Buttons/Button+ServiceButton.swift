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

/// Creates Buttons for ServiceDetailViewController
extension Button {
    @objc public static func createAddServiceButton() -> Button {
        return Button.createButton(styleClass: "dialogue-button-full",
                                   title: "peoplepicker.services.add_service.button".localized)
    }

    @objc public static func createServiceConversationButton() -> Button {
        return Button.createButton(styleClass: "dialogue-button-full",
                                   title: "peoplepicker.services.create_conversation.item".localized)
    }

    @objc public static func createDestructiveServiceButton() -> Button {
        let button = Button.createButton(styleClass: "dialogue-button-full-destructive",
                                   title: "participants.services.remove_integration.button".localized)

        button.setBackgroundImageColor(.vividRed, for: .normal)
        return button
    }

    private static func createButton(styleClass:String, title:String) -> Button {
        let button = Button(styleClass: styleClass)
        button.setTitle(title, for: .normal)

        return button
    }
}
