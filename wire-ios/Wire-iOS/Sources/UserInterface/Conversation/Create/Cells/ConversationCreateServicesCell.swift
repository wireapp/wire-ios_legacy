//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireCommonComponents
import UIKit

final class ConversationCreateServicesCell: IconToggleCell {

    override func setUp() {
        super.setUp()
        accessibilityIdentifier = "toggle.newgroup.allowservices"
        title = L10n.Localizable.Conversation.Create.Services.title
        showSeparator = false
    }

    override func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        super.applyColorScheme(colorSchemeVariant)
        let color = UIColor.from(scheme: .textForeground, variant: colorSchemeVariant)
        icon = StyleKitIcon.bot.makeImage(size: .tiny, color: color)
    }
}

extension ConversationCreateServicesCell: ConversationCreationValuesConfigurable {
    func configure(with values: ConversationCreationValues) {
        isOn = values.allowServices
    }
}
