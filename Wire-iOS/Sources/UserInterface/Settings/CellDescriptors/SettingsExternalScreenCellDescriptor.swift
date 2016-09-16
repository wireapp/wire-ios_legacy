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
    case Modal
    case Navigation
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
    
    init(title: String, presentationAction: () -> (UIViewController?)) {
        self.title = title
        self.destructive = false
        self.presentationStyle = .Navigation
        self.presentationAction = presentationAction
        self.identifier = .None
        self.previewGenerator = .None
        self.icon = .None
    }
    
    init(title: String, isDestructive: Bool, presentationStyle: PresentationStyle, presentationAction: () -> (UIViewController?), previewGenerator: PreviewGeneratorType? = .None, icon: ZetaIconType = .None) {
        self.title = title
        self.destructive = isDestructive
        self.presentationStyle = presentationStyle
        self.presentationAction = presentationAction
        self.identifier = .None
        self.previewGenerator = previewGenerator
        self.icon = icon
    }
    
    init(title: String, isDestructive: Bool, presentationStyle: PresentationStyle, identifier: String, presentationAction: () -> (UIViewController?), previewGenerator: PreviewGeneratorType? = .None, icon: ZetaIconType = .None) {
        self.title = title
        self.destructive = isDestructive
        self.presentationStyle = presentationStyle
        self.presentationAction = presentationAction
        self.identifier = identifier
        self.previewGenerator = previewGenerator
        self.icon = icon
    }
    
    func select(value: SettingsPropertyValue?) {
        guard let controllerToShow = self.generateViewController() else {
            return
        }
        
        switch self.presentationStyle {
        case .Modal:
            self.viewController?.presentViewController(controllerToShow, animated: true, completion: .None)
        case .Navigation:
            if let navigationController = self.viewController?.navigationController {
                navigationController.pushViewController(controllerToShow, animated: true)
            }
        }
    }
    
    func featureCell(cell: SettingsCellType) {
        cell.titleText = self.title
        if self.destructive {
            cell.titleColor = UIColor.redColor()
        }
        else {
            cell.titleColor = UIColor.whiteColor()
        }
        if let previewGenerator = self.previewGenerator {
            let preview = previewGenerator(self)
            cell.preview = preview
        }
        cell.icon = self.icon
        if let groupCell = cell as? SettingsGroupCell {
            if self.presentationStyle == .Modal {
                groupCell.accessoryType = .None
            } else {
                groupCell.accessoryType = .DisclosureIndicator
            }
        }
    }
    
    func generateViewController() -> UIViewController? {
        return self.presentationAction()
    }
}
