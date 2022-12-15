// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

import Foundation
import UIKit
import WireCommonComponents

enum PresentationStyle: Int {
    case modal
    case navigation
    case alert
}

enum AccessoryViewMode: Int {
    case `default`
    case alwaysShow
    case alwaysHide
}

class SettingsExternalScreenCellDescriptor: SettingsExternalScreenCellDescriptorType, SettingsControllerGeneratorType {
    static let cellType: SettingsTableCellProtocol.Type = SettingsTableCell.self
    var visible: Bool = true
    let title: String
    let destructive: Bool
    let presentationStyle: PresentationStyle
    let identifier: String?
    let icon: StyleKitIcon?

    private let accessoryViewMode: AccessoryViewMode

    weak var group: SettingsGroupCellDescriptorType?
    weak var viewController: UIViewController?

    let previewGenerator: PreviewGeneratorType?

    let presentationAction: () -> (UIViewController?)

    convenience init(title: String, presentationAction: @escaping () -> (UIViewController?)) {
        self.init(
            title: title,
            isDestructive: false,
            presentationStyle: .navigation,
            identifier: nil,
            presentationAction: presentationAction,
            previewGenerator: nil,
            icon: .none
        )
    }

    convenience init(title: String,
                     isDestructive: Bool,
                     presentationStyle: PresentationStyle,
                     presentationAction: @escaping () -> (UIViewController?),
                     previewGenerator: PreviewGeneratorType? = .none,
                     icon: StyleKitIcon? = nil,
                     accessoryViewMode: AccessoryViewMode = .default) {
        self.init(
            title: title,
            isDestructive: isDestructive,
            presentationStyle: presentationStyle,
            identifier: nil,
            presentationAction: presentationAction,
            previewGenerator: previewGenerator,
            icon: icon,
            accessoryViewMode: accessoryViewMode
        )
    }

    init(title: String,
         isDestructive: Bool,
         presentationStyle: PresentationStyle,
         identifier: String?,
         presentationAction: @escaping () -> (UIViewController?),
         previewGenerator: PreviewGeneratorType? = .none,
         icon: StyleKitIcon? = nil,
         accessoryViewMode: AccessoryViewMode = .default) {

        self.title = title
        self.destructive = isDestructive
        self.presentationStyle = presentationStyle
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

        switch self.presentationStyle {
        case .modal:
            if controllerToShow.modalPresentationStyle == .popover,
                let sourceView = self.viewController?.view,
                let popoverPresentation = controllerToShow.popoverPresentationController {
                popoverPresentation.sourceView = sourceView
                popoverPresentation.sourceRect = sourceView.bounds
            }

            controllerToShow.modalPresentationCapturesStatusBarAppearance = true
            self.viewController?.present(controllerToShow, animated: true, completion: .none)
        case .navigation:
            viewController?.navigationController?.pushViewController(controllerToShow, animated: true)
        case .alert:
            break
        }
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
            switch accessoryViewMode {
            case .default:
                if self.presentationStyle == .modal {
                    groupCell.hideDisclosureIndicator()
                } else {
                    groupCell.showDisclosureIndicator()
                }
            case .alwaysHide:
                groupCell.hideDisclosureIndicator()
            case .alwaysShow:
                groupCell.showDisclosureIndicator()
            }
        }
    }

    func generateViewController() -> UIViewController? {
        return self.presentationAction()
    }
}
