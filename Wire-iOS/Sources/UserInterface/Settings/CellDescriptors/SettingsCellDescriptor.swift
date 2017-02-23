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

typealias PreviewGeneratorType = (SettingsCellDescriptorType) -> SettingsCellPreview

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
    case plain
    case grouped
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

    let header: String?
    let footer: String?
    
    init(cellDescriptors: [SettingsCellDescriptorType], header: String? = .none, footer: String? = .none, visibilityAction: ((SettingsSectionDescriptorType) -> (Bool))? = .none) {
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
    let icon: ZetaIconType
    
    let previewGenerator: PreviewGeneratorType?
    
    weak var group: SettingsGroupCellDescriptorType?
    
    var visibleItems: [SettingsSectionDescriptorType] {
        return self.items.filter {
            $0.visible
        }
    }
    
    weak var viewController: UIViewController?
    
    init(items: [SettingsSectionDescriptorType], title: String, style: InternalScreenStyle = .grouped, identifier: String? = .none, previewGenerator: PreviewGeneratorType? = .none, icon: ZetaIconType = .none) {
        self.items = items
        self.title = title
        self.style = style
        self.identifier = identifier
        self.previewGenerator = previewGenerator
        self.icon = icon
    }
    
    func featureCell(_ cell: SettingsCellType) {
        cell.titleText = self.title
        if let previewGenerator = self.previewGenerator {
            let preview = previewGenerator(self)
            cell.preview = preview
        }
        cell.icon = self.icon
    }
    
    func select(_ value: SettingsPropertyValue?) {
        if let navigationController = self.viewController?.navigationController,
           let controllerToPush = self.generateViewController() {
            navigationController.pushViewController(controllerToPush, animated: true)
            
            if let settingsTableController = controllerToPush as? SettingsTableViewController,
                let settingsNavigationController = navigationController as? SettingsNavigationController {
                settingsTableController.dismissAction = { [unowned settingsNavigationController]  _ in
                    settingsNavigationController.dismissAction?(settingsNavigationController)
                }
            }
        }
    }
    
    func generateViewController() -> UIViewController? {
        return SettingsTableViewController(group: self)
    }
}

// MARK: - Helpers

func SettingsPropertyLabelText(_ name: SettingsPropertyName) -> String {
    switch (name) {
    case .chatHeadsDisabled:
        return "self.settings.notifications.chat_alerts.toggle".localized
    case .notificationContentVisible:
        return "self.settings.notifications.push_notification.toogle".localized
    case .markdown:
        return "Markdown support"
        
    case .skipFirstTimeUseChecks:
        return "Skip first time use checks"
        
    case .preferredFlashMode:
        return "Flash Mode"
    case .darkMode:
        return "self.settings.account_picture_group.theme".localized
        // Profile
    case .profileName:
        return "self.settings.account_section.name.title".localized
        
        // AVS
    case .soundAlerts:
        return "self.settings.sound_menu.title".localized
        
        // Analytics
    case .analyticsOptOut:
        return "self.settings.privacy_analytics_section.title".localized
        
    case .disableUI:
        return "Disable UI (Restart needed)"
    case .disableHockey:
        return "Disable Hockey (Restart needed)"
    case .disableAVS:
        return "Disable AVS (Restart needed)"
    case .disableAnalytics:
        return "Disable Analytics (Restart needed)"
    case .messageSoundName:
        return "self.settings.sound_menu.message.title".localized
    case .callSoundName:
        return "self.settings.sound_menu.ringtone.title".localized
    case .pingSoundName:
        return "self.settings.sound_menu.ping.title".localized
    case .accentColor:
        return "self.settings.account_picture_group.color".localized
    case .disableSendButton:
        return "self.settings.popular_demand.send_button.title".localized
    case .disableCallKit:
        return "self.settings.callkit.caption".localized
    case .tweetOpeningOption:
        return "self.settings.link_options.twitter.title".localized
    case .mapsOpeningOption:
        return "self.settings.link_options.maps.title".localized
    case .browserOpeningOption:
        return "self.settings.link_options.browser.title".localized
    case .sendV3Assets:
        return "Send assets using the v3 endpoint"
    case .callingProtocolStrategy:
        return "Calling protocol"
    case .enableBatchCollections:
        return "Use AssetCollectionBatched"
    case .lockApp:
        return "self.settings.privacy_security.lock_app".localized
    case .lockAppLastDate:
        return "Last app lock date"
    }
}

