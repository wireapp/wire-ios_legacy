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

import WireCommonComponents
import UIKit

final class ConversationCreateOptionsCell: RightIconDetailsCell {

    var expanded = false {
        didSet { applyColorScheme(colorSchemeVariant) }
    }

    override func setUp() {
        super.setUp()
        accessibilityIdentifier = "cell.groupdetails.options"
        title = "conversation.create.options.title".localized
        icon = nil
        showSeparator = false
        contentLeadingOffset = 16
    }

    override func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        super.applyColorScheme(colorSchemeVariant)

        let color = SemanticColors.Icon.foregroundPlainDownArrow
        let image = StyleKitIcon.downArrow.makeImage(size: .tiny, color: color).withRenderingMode(.alwaysTemplate)

        // flip upside down if necessary
        if let cgImage = image.cgImage, expanded {
            accessory = UIImage(cgImage: cgImage, scale: image.scale, orientation: .downMirrored).withRenderingMode(.alwaysTemplate)
            accessoryColor = color
        } else {
            accessory = StyleKitIcon.downArrow.makeImage(size: .tiny, color: color).withRenderingMode(.alwaysTemplate)
            accessoryColor = color
        }
    }
}

extension ConversationCreateOptionsCell: ConversationCreationValuesConfigurable {
    func configure(with values: ConversationCreationValues) {
        let guests = values.allowGuests.localized.localizedUppercase
        let services = values.allowServices.localized.localizedUppercase
        let receipts = values.enableReceipts.localized.localizedUppercase
        status = L10n.Localizable.Conversation.Create.Options.subtitle(guests, services, receipts)
    }
}

private extension Bool {
    var localized: String {
        return self ? "general.on".localized : "general.off".localized
    }
}
