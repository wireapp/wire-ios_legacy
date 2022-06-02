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

class SettingsProfileLinkCellDescriptor: SettingsCellDescriptorType {
    static let cellType: SettingsTableCell.Type = SettingsProfileLinkCell.self

    // MARK: - Configuration

    func featureCell(_ cell: SettingsCellType) {
        (cell as! SettingsProfileLinkCell).label.attributedText = title && .lineSpacing(8)
    }

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
        // no-op
    }
}
