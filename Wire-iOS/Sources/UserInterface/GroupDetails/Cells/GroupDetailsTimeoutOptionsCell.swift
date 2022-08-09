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
import WireCommonComponents
import WireDataModel

final class GroupDetailsTimeoutOptionsCell: GroupDetailsDisclosureOptionsCell {

    override func setUp() {
        super.setUp()
        accessibilityIdentifier = "cell.groupdetails.timeoutoptions"
        title = "group_details.timeout_options_cell.title".localized
    }

    func configure(with conversation: GroupDetailsConversationType) {
        let timeout = MessageDestructionTimeoutValue(rawValue: conversation.syncedMessageDestructionTimeout)
        status = timeout.displayString
    }

    override func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        super.applyColorScheme(colorSchemeVariant)
        iconColor = SemanticColors.Icon.foregroundCellIconActive
        guard let iconColor = iconColor else { return }
        icon = StyleKitIcon.hourglass.makeImage(size: .tiny,
                                                color: iconColor).withRenderingMode(.alwaysTemplate)
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted
            ? SemanticColors.View.Background.backgroundUserCellHightLighted
            : SemanticColors.View.Background.backgroundUserCell
        }
    }

}
