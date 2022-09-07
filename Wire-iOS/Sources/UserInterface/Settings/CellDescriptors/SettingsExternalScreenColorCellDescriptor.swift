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

class SettingsExternalScreenColorCellDescriptor: SettingsExternalScreenCellDescriptorType, SettingsControllerGeneratorType {
    static let cellType: SettingsTableCell.Type = SettingsTableColorCell.self
    var visible: Bool = true
    let title: String
    let identifier: String?
    let icon: StyleKitIcon?

    private let accessoryViewMode: AccessoryViewMode

    weak var group: SettingsGroupCellDescriptorType?
    weak var viewController: UIViewController?

    let previewGenerator: PreviewGeneratorType?

    let presentationAction: () -> (UIViewController?)

    init(title: String,
         identifier: String?,
         presentationAction: @escaping () -> (UIViewController?),
         previewGenerator: PreviewGeneratorType? = .none,
         icon: StyleKitIcon? = nil,
         accessoryViewMode: AccessoryViewMode = .default) {

        self.title = title
        self.presentationAction = presentationAction
        self.identifier = identifier
        self.previewGenerator = previewGenerator
        self.icon = icon
        self.accessoryViewMode = accessoryViewMode
    }

    func select(_ value: SettingsPropertyValue?) {
        guard let controllerToShow = self.generateViewController() else {
            return
        }
        viewController?.navigationController?.pushViewController(controllerToShow, animated: true)
    }

    func featureCell(_ cell: SettingsCellType) {
        cell.titleText = self.title

        if let tableCell = cell as? SettingsTableCell {
            tableCell.valueLabel.accessibilityIdentifier = title + "Field"
            tableCell.valueLabel.isAccessibilityElement = true
        }

        if let previewGenerator = self.previewGenerator {
            let preview = previewGenerator(self)
            cell.preview = preview
        }
        cell.icon = self.icon
        if let groupCell = cell as? SettingsTableCell {
            groupCell.showDisclosureIndicator()
        }
    }

    func generateViewController() -> UIViewController? {
        return self.presentationAction()
    }
}
