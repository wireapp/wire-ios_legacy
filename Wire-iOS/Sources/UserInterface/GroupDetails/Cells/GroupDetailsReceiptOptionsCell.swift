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

class GroupDetailsReceiptOptionsCell: DetailsCollectionViewCell {

    var isOn: Bool {
        set {
            toggle.isOn = newValue
        }

        get {
            return toggle.isOn
        }
    }

    private let toggle = UISwitch()
    var action: ((Bool) -> Void)?

    override func setUp() {
        super.setUp()
        accessibilityIdentifier = "cell.groupdetails.receiptoptions"
        title = "group_details.receipt_options_cell.title".localized

        contentStackView.insertArrangedSubview(toggle, at: contentStackView.arrangedSubviews.count - 1)

        toggle.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)
    }

    override func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        super.applyColorScheme(colorSchemeVariant)
        icon = UIImage(for: .eye,
                       iconSize: .tiny,
                       color: UIColor.from(scheme: .textForeground, variant: colorSchemeVariant))
    }

    @objc func toggleChanged(_ sender: UISwitch) {
        action?(sender.isOn)
    }
}

extension GroupDetailsReceiptOptionsCell: ConversationOptionsConfigurable {
    func configure(with conversation: ZMConversation) {
         isOn = conversation.hasReadReceiptsEnabled
    }
}
