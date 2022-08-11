////
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import WireDataModel
import WireCommonComponents

final class GroupDetailsNotificationOptionsCell: GroupDetailsDisclosureOptionsCell {

    override func setUp() {
        super.setUp()
        accessibilityIdentifier = "cell.groupdetails.notificationsoptions"
        title = "group_details.notification_options_cell.title".localized
    }

    func configure(with conversation: GroupDetailsConversationType) {
        guard let key = conversation.mutedMessageTypes.localizationKey else {
            return assertionFailure("Invalid muted message type.")
        }

        status = key.localized
    }

    override func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        super.applyColorScheme(colorSchemeVariant)
        iconColor = SemanticColors.Icon.foregroundDefault
        guard let iconColor = iconColor else { return }

        icon = StyleKitIcon.alerts.makeImage(size: .tiny,
                                             color: iconColor).withRenderingMode(.alwaysTemplate)
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted
            ? SemanticColors.View.backgroundUserCellHightLighted
            : SemanticColors.View.backgroundUserCell
        }
    }

}
