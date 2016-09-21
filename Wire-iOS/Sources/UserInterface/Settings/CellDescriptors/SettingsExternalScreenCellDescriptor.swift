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

enum PresentationStyle: Int {
    case modal
    case navigation
}

class SettingsExternalScreenCellDescriptor: SettingsExternalScreenCellDescriptorType, SettingsControllerGeneratorType {
    static let cellType: SettingsTableCell.Type = SettingsGroupCell.self
    var visible: Bool = true
    let title: String
    let destructive: Bool
    let presentationStyle: PresentationStyle
    let identifier: String?
    let icon: ZetaIconType

    weak var group: SettingsGroupCellDescriptorType?
    weak var viewController: UIViewController?
    
    let previewGenerator: PreviewGeneratorType?

    let presentationAction: () -> (UIViewController?)
    
    init(title: String, presentationAction: @escaping () -> (UIViewController?)) {
        self.title = title
        self.destructive = false
        self.presentationStyle = .navigation
        self.presentationAction = presentationAction
        self.identifier = .none
        self.previewGenerator = .none
        self.icon = .none
    }
    
    init(title: String, isDestructive: Bool, presentationStyle: PresentationStyle, presentationAction: @escaping () -> (UIViewController?), previewGenerator: PreviewGeneratorType? = .none, icon: ZetaIconType = .none) {
        self.title = title
        self.destructive = isDestructive
        self.presentationStyle = presentationStyle
        self.presentationAction = presentationAction
        self.identifier = .none
        self.previewGenerator = previewGenerator
        self.icon = icon
    }
    
    init(title: String, isDestructive: Bool, presentationStyle: PresentationStyle, identifier: String, presentationAction: @escaping () -> (UIViewController?), previewGenerator: PreviewGeneratorType? = .none, icon: ZetaIconType = .none) {
        self.title = title
        self.destructive = isDestructive
        self.presentationStyle = presentationStyle
        self.presentationAction = presentationAction
        self.identifier = identifier
        self.previewGenerator = previewGenerator
        self.icon = icon
    }
    
    func select(_ value: SettingsPropertyValue?) {
        guard let controllerToShow = self.generateViewController() else {
            return
        }
        
        switch self.presentationStyle {
        case .modal:
            self.viewController?.present(controllerToShow, animated: true, completion: .none)
        case .navigation:
            if let navigationController = self.viewController?.navigationController {
                navigationController.pushViewController(controllerToShow, animated: true)
            }
        }
    }
    
    func featureCell(_ cell: SettingsCellType) {
        cell.titleText = self.title
        if self.destructive {
            cell.titleColor = UIColor.red
        }
        else {
            cell.titleColor = UIColor.white
        }
        if let previewGenerator = self.previewGenerator {
            let preview = previewGenerator(self)
            cell.preview = preview
        }
        cell.icon = self.icon
        if let groupCell = cell as? SettingsGroupCell {
            if self.presentationStyle == .modal {
                groupCell.accessoryType = .none
            } else {
                groupCell.accessoryType = .disclosureIndicator
            }
        }
    }
    
    func generateViewController() -> UIViewController? {
        return self.presentationAction()
    }
}
