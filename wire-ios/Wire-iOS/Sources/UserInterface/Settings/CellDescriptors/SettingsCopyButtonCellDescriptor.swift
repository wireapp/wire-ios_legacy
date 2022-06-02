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

protocol IconActionCellDelegate: AnyObject {
    func updateLayout()
}

class SettingsCopyButtonCellDescriptor: SettingsCellDescriptorType {
    static let cellType: SettingsTableCell.Type = IconActionCell.self

    weak var delegate: IconActionCellDelegate?

    var copyInProgress = false {
        didSet {
            delegate?.updateLayout()
        }
    }

    // MARK: - Configuration

    func featureCell(_ cell: SettingsCellType) {
        if let iconActionCell = cell as? IconActionCell {
            delegate = iconActionCell
            iconActionCell.configure(with: copyInProgress ? copiedLink : copyLink,
                                     variant: .dark)
        }
    }

    // MARK: - Helpers

    typealias Actions =  L10n.Localizable.Self.Settings.AccountSection.ProfileLink.Actions

    let copiedLink: CellConfiguration = .iconAction(title: Actions.copiedLink,
                                                    icon: .checkmark,
                                                    color: nil,
                                                    action: {_ in }
    )

    let copyLink: CellConfiguration = .iconAction(title: Actions.copyLink,
                                                  icon: .copy,
                                                  color: nil,
                                                  action: {_ in }
    )

    // MARK: - SettingsCellDescriptorType

    var visible: Bool {
        return true
    }

    var title: String {
        return URL.selfUserProfileLink?.absoluteString.removingPercentEncoding ?? ""
    }

    var identifier: String?
    weak var group: SettingsGroupCellDescriptorType?
    var previewGenerator: PreviewGeneratorType?

    func select(_ value: SettingsPropertyValue?) {
        UIPasteboard.general.string = title
        copyInProgress = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.copyInProgress = false
        }
    }
}
