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

class SettingsAppearanceCellDescriptor: SettingsCellDescriptorType, SettingsExternalScreenCellDescriptorType {
    static let cellType: SettingsTableCellProtocol.Type = SettingsAppearanceCell.self

    private var text: String
    private let appearanceType: AppearanceType
    weak var viewController: UIViewController?
    let presentationAction: () -> (UIViewController?)

    init(text: String, appearanceType: AppearanceType, presentationAction: @escaping () -> (UIViewController?)) {
        self.text = text
        self.appearanceType = appearanceType
        self.presentationAction = presentationAction
    }

    // MARK: - Configuration

    func featureCell(_ cell: SettingsCellType) {
        if let appearanceCell = cell as? SettingsAppearanceCell {
            appearanceCell.configure(with: .appearance(title: text), variant: .dark)

            switch appearanceType {
            case .color:
                appearanceCell.showDisclosureIndicator()
            case .photo: break
            }

        }
    }

    // MARK: - SettingsCellDescriptorType

    var visible: Bool {
        return true
    }

    var title: String {
        return text
    }

    var identifier: String?
    weak var group: SettingsGroupCellDescriptorType?
    var previewGenerator: PreviewGeneratorType?

    func select(_ value: SettingsPropertyValue?) {
        guard let controllerToShow = self.generateViewController() else {
            return
        }
        viewController?.navigationController?.pushViewController(controllerToShow, animated: true)
    }

    func generateViewController() -> UIViewController? {
        return self.presentationAction()
    }
}

enum AppearanceType {
    case color
    case photo
}
