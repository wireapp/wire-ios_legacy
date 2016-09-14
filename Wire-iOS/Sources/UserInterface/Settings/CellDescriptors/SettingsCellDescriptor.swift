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


/**
 * Top-level structure overview:
 * Settings group (screen) @c SettingsGroupCellDescriptorType contains
 * |--Settings section (table view section) @c SettingsSectionDescriptorType
 * |   |--Cell @c SettingsCellDescriptorType
 * |   |--Subgroup @c SettingsGroupCellDescriptorType
 * |   |  \..
 * |   \..
 * \...
 */

// MARK: - Protocols

/**
 * @abstract Top-level protocol for model object of settings. Describes the way cell should be created or how the value
 * should be updated from the cell.
 */
protocol SettingsCellDescriptorType: class {
    static var cellType: SettingsTableCell.Type {get}
    var visible: Bool {get}
    var title: String {get}
    var identifier: String? {get}
    weak var group: SettingsGroupCellDescriptorType? {get}
    
    func select(_: SettingsPropertyValue?)
    func featureCell(_: SettingsCellType)
}

func ==(left: SettingsCellDescriptorType, right: SettingsCellDescriptorType) -> Bool {
    if let leftID = left.identifier,
        let rightID = right.identifier {
            return leftID == rightID
    }
    else {
        return left == right
    }
}

typealias PreviewGeneratorType = (SettingsGroupCellDescriptorType) -> SettingsCellPreview

protocol SettingsGroupCellDescriptorType: SettingsCellDescriptorType {
    weak var viewController: UIViewController? {get set}
}

protocol SettingsSectionDescriptorType: class {
    var cellDescriptors: [SettingsCellDescriptorType] {get}
    var visibleCellDescriptors: [SettingsCellDescriptorType] {get}
    var header: String? {get}
    var footer: String? {get}
    var visible: Bool {get}
}

extension SettingsSectionDescriptorType {
    func allCellDescriptors() -> [SettingsCellDescriptorType] {
        return cellDescriptors
    }
}

enum InternalScreenStyle {
    case Plain
    case Grouped
}

protocol SettingsInternalGroupCellDescriptorType: SettingsGroupCellDescriptorType {
    var items: [SettingsSectionDescriptorType] {get}
    var visibleItems: [SettingsSectionDescriptorType] {get}
    var style: InternalScreenStyle {get}
}

extension SettingsInternalGroupCellDescriptorType {
    func allCellDescriptors() -> [SettingsCellDescriptorType] {
        return items.flatMap({ (section: SettingsSectionDescriptorType) -> [SettingsCellDescriptorType] in
            return section.allCellDescriptors()
        })
    }
}

protocol SettingsExternalScreenCellDescriptorType: SettingsGroupCellDescriptorType {
    var presentationAction: () -> (UIViewController?) {get}
}

protocol SettingsPropertyCellDescriptorType: SettingsCellDescriptorType {
    var settingsProperty: SettingsProperty {get}
}

protocol SettingsControllerGeneratorType {
    func generateViewController() -> UIViewController?
}

// MARK: - Classes

class SettingsSectionDescriptor: SettingsSectionDescriptorType {
    let cellDescriptors: [SettingsCellDescriptorType]
    var visibleCellDescriptors: [SettingsCellDescriptorType] {
        return self.cellDescriptors.filter {
            $0.visible
        }
    }
    var visible: Bool {
        get {
            if let visibilityAction = self.visibilityAction {
                return visibilityAction(self)
            }
            else {
                return true
            }
        }
    }
    let visibilityAction: ((SettingsSectionDescriptorType) -> (Bool))?

    var header: String?
    var footer: String?
    
    init(cellDescriptors: [SettingsCellDescriptorType], header: String? = .None, footer: String? = .None, visibilityAction: ((SettingsSectionDescriptorType) -> (Bool))? = .None) {
        self.cellDescriptors = cellDescriptors
        self.header = header
        self.footer = footer
        self.visibilityAction = visibilityAction
    }
}


class SettingsGroupCellDescriptor: SettingsInternalGroupCellDescriptorType, SettingsControllerGeneratorType {
    static let cellType: SettingsTableCell.Type = SettingsGroupCell.self
    var visible: Bool = true
    let title: String
    let style: InternalScreenStyle
    let items: [SettingsSectionDescriptorType]
    let identifier: String?
    
    let previewGenerator: PreviewGeneratorType?
    
    weak var group: SettingsGroupCellDescriptorType?
    
    var visibleItems: [SettingsSectionDescriptorType] {
        return self.items.filter {
            $0.visible
        }
    }
    
    weak var viewController: UIViewController?
    
    init(items: [SettingsSectionDescriptorType], title: String, style: InternalScreenStyle = .Grouped, identifier: String? = .None, previewGenerator: PreviewGeneratorType? = .None) {
        self.items = items
        self.title = title
        self.style = style
        self.identifier = identifier
        self.previewGenerator = previewGenerator
    }
    
    func featureCell(cell: SettingsCellType) {
        cell.titleText = self.title
        if let previewGenerator = self.previewGenerator {
            let preview = previewGenerator(self)
            cell.preview = preview
        }
    }
    
    func select(value: SettingsPropertyValue?) {
        if let navigationController = self.viewController?.navigationController,
           let controllerToPush = self.generateViewController() {
            navigationController.pushViewController(controllerToPush, animated: true)
        }
    }
    
    func generateViewController() -> UIViewController? {
        return SettingsTableViewController(group: self)
    }
}

// MARK: - Helpers

func SettingsPropertyLabelText(name: SettingsPropertyName) -> String {
    switch (name) {
    case .ChatHeadsDisabled:
        return "self.settings.notifications.chat_alerts.toggle".localized
    case .NotificationContentVisible:
        return "self.settings.notifications.push_notification.toogle".localized
    case .Markdown:
        return "Markdown support"
        
    case .SkipFirstTimeUseChecks:
        return "Skip first time use checks"
        
    case .PreferredFlashMode:
        return "Flash Mode"
    case .DarkMode:
        return "self.settings.account_picture_group.theme".localized
        // Profile
    case .ProfileName:
        return "self.settings.account_section.name.title".localized
    case .ProfileEmail:
        return "self.settings.account_section.email.title".localized
    case .ProfilePhone:
        return "self.settings.account_section.phone.title".localized
        
        // AVS
    case .SoundAlerts:
        return "self.settings.sound_menu.title".localized
        
        // Analytics
    case .AnalyticsOptOut:
        return "self.settings.privacy_analytics_section.title".localized
        
    case .DisableUI:
        return "Disable UI (Restart needed)"
    case .DisableHockey:
        return "Disable Hockey (Restart needed)"
    case .DisableAVS:
        return "Disable AVS (Restart needed)"
    case .DisableAnalytics:
        return "Disable Analytics (Restart needed)"
    case .MessageSoundName:
        return "self.settings.sound_menu.message.title".localized
    case .CallSoundName:
        return "self.settings.sound_menu.ringtone.title".localized
    case .PingSoundName:
        return "self.settings.sound_menu.ping.title".localized
    case .AccentColor:
        return "self.settings.account_picture_group.color".localized
    }
}

