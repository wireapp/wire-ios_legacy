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

import UIKit
import WireCommonComponents
import WireDataModel

final class GroupDetailsServicesCell: GroupDetailsDisclosureOptionsCell {

    var isOn = false {
        didSet {
            let key = "group_details.services_options_cell.\(isOn ? "enabled" : "disabled")"
            status = key.localized
        }
    }

    override func setUp() {
        super.setUp()
        accessibilityIdentifier = "cell.groupdetails.servicesoptions"
        title = "group_details.services_options_cell.title".localized
    }

    func configure(with conversation: GroupDetailsConversationType) {
        //TODO: This needs to change to .allowServices when I make the changes to Data Model
        isOn = conversation.allowGuests
    }

    override func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        super.applyColorScheme(colorSchemeVariant)

        icon = StyleKitIcon.bot.makeImage(size: .tiny,
                                            color: UIColor.from(scheme: .textForeground, variant: colorSchemeVariant))
    }

}
