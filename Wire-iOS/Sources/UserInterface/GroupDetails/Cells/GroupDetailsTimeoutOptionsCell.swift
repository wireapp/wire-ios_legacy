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

protocol ConversationOptionsConfigurable {
    func configure(with conversation: ZMConversation)
}

protocol GroupDetailsOptionsCell where Self: DetailsCollectionViewCell {
    func setAccessoryAsDisclosureIndicator(colorSchemeVariant: ColorSchemeVariant)
}

extension GroupDetailsOptionsCell where Self: DetailsCollectionViewCell {


    /// call this method in override func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant)
    ///
    /// - Parameter colorSchemeVariant: the colorSchemeVariant for the right icon image
    func setAccessoryAsDisclosureIndicator(colorSchemeVariant: ColorSchemeVariant) {
        let sectionTextColor = UIColor.from(scheme: .sectionText, variant: colorSchemeVariant)
        accessoryImage = UIImage(for: .disclosureIndicator, iconSize: .like, color: sectionTextColor)
    }
}

typealias ConversationOptionsCell = DetailsCollectionViewCell & ConversationOptionsConfigurable
typealias GroupDetailsDisclosureOptionsCell = ConversationOptionsCell & GroupDetailsOptionsCell

class GroupDetailsTimeoutOptionsCell: GroupDetailsDisclosureOptionsCell {

    override func setUp() {
        super.setUp()
        accessibilityIdentifier = "cell.groupdetails.timeoutoptions"
        title = "group_details.timeout_options_cell.title".localized
    }

    func configure(with conversation: ZMConversation) {
        switch conversation.messageDestructionTimeout {
        case .synced(let value)?:
            status = value.displayString
        default:
            status = MessageDestructionTimeoutValue.none.displayString
        }
    }

    override func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        super.applyColorScheme(colorSchemeVariant)
        setAccessoryAsDisclosureIndicator(colorSchemeVariant: colorSchemeVariant)

        icon = UIImage(for: .hourglass, iconSize: .tiny,
                       color: UIColor.from(scheme: .textForeground, variant: colorSchemeVariant))
    }

}
