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
import WireCommonComponents
import UIKit

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
protocol SettingsCellDescriptorType: AnyObject {
    static var cellType: SettingsTableCell.Type {get}
    var visible: Bool {get}
    var title: String {get}
    var identifier: String? {get}
    var group: SettingsGroupCellDescriptorType? {get}

    func select(_: SettingsPropertyValue?)
    func featureCell(_: SettingsCellType)
}

func == (left: SettingsCellDescriptorType, right: SettingsCellDescriptorType) -> Bool {
    if let leftID = left.identifier,
        let rightID = right.identifier {
            return leftID == rightID
    } else {
        return left == right
    }
}

typealias PreviewGeneratorType = (SettingsCellDescriptorType) -> SettingsCellPreview

protocol SettingsGroupCellDescriptorType: SettingsCellDescriptorType {
    var viewController: UIViewController? {get set}
}

protocol SettingsSectionDescriptorType: AnyObject {
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
        return visibilityAction?(self) ?? true
    }
    let visibilityAction: ((SettingsSectionDescriptorType) -> (Bool))?

    var header: String? {
        return headerGenerator()
    }
    var footer: String? {
        return footerGenerator()
    }

    let headerGenerator: () -> String?
    let footerGenerator: () -> String?

    convenience init(cellDescriptors: [SettingsCellDescriptorType], header: String? = .none, footer: String? = .none, visibilityAction: ((SettingsSectionDescriptorType) -> (Bool))? = .none) {
        self.init(cellDescriptors: cellDescriptors, headerGenerator: { return header }, footerGenerator: { return footer}, visibilityAction: visibilityAction)
    }

    init(cellDescriptors: [SettingsCellDescriptorType], headerGenerator: @escaping () -> String?, footerGenerator: @escaping () -> String?, visibilityAction: ((SettingsSectionDescriptorType) -> (Bool))? = .none) {
        self.cellDescriptors = cellDescriptors
        self.headerGenerator = headerGenerator
        self.footerGenerator = footerGenerator
        self.visibilityAction = visibilityAction
    }
}

final class SettingsGroupCellDescriptor: SettingsInternalGroupCellDescriptorType, SettingsControllerGeneratorType {
    static let cellType = SettingsTableCell.self
    var visible: Bool = true
    let title: String
    let style: InternalScreenStyle
    let items: [SettingsSectionDescriptorType]
    let identifier: String?
    let icon: StyleKitIcon?

    let previewGenerator: PreviewGeneratorType?

    weak var group: SettingsGroupCellDescriptorType?

    var visibleItems: [SettingsSectionDescriptorType] {
        return self.items.filter {
            $0.visible
        }
    }

    weak var viewController: UIViewController?

    init(items: [SettingsSectionDescriptorType], title: String, style: InternalScreenStyle = .grouped, identifier: String? = .none, previewGenerator: PreviewGeneratorType? = .none, icon: StyleKitIcon? = nil) {
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
        if let cell = cell as? SettingsTableCell {
            cell.showDisclosureIndicator()
        }
    }

    func select(_ value: SettingsPropertyValue?) {
        if let navigationController = viewController?.navigationController,
           let controllerToPush = generateViewController() {
            navigationController.pushViewController(controllerToPush, animated: true)
        }
    }

    func generateViewController() -> UIViewController? {
        return SettingsTableViewController(group: self)
    }
}

// MARK: - Helpers

extension SettingsPropertyName {

    var settingsPropertyLabelText: String {
        typealias Settings = L10n.Localizable.Self.Settings
        typealias Notifications = Settings.Notifications
        typealias Account = Settings.AccountSection
        typealias SoundMenu = Settings.SoundMenu
        typealias LinkOptions = Settings.LinkOptions

        switch self {
        case .chatHeadsDisabled:
            return Notifications.ChatAlerts.toggle
        case .notificationContentVisible:
            return Notifications.PushNotification.toogle
        case .disableMarkdown:
            return "Disable Markdown support"
        case .darkMode:
            return Settings.AccountPictureGroup.theme

        // Profile
        case .profileName:
            return Account.Name.title
        case .handle:
            return Account.Handle.title
        case .email:
            return Account.Email.title
        case .phone:
            return Account.Phone.title
        case .team:
            return Account.Team.title
        case .domain:
            return Account.Domain.title

        // AVS
        case .soundAlerts:
            return SoundMenu.title
        case .messageSoundName:
            return SoundMenu.Message.title
        case .callSoundName:
            return SoundMenu.Ringtone.title
        case .pingSoundName:
            return SoundMenu.Ping.title

        case .accentColor:
            return Settings.AccountPictureGroup.color
        case .disableSendButton:
            return Settings.PopularDemand.SendButton.title
        case .disableCallKit:
            return Settings.Callkit.caption
        case .muteIncomingCallsWhileInACall:
            return Settings.MuteOtherCall.caption
        case .tweetOpeningOption:
            return LinkOptions.Twitter.title
        case .mapsOpeningOption:
            return LinkOptions.Maps.title
        case .browserOpeningOption:
            return LinkOptions.Browser.title
        case .callingProtocolStrategy:
            return "Calling protocol"
        case .enableBatchCollections:
            return "Use AssetCollectionBatched"
        case .lockApp:
            return Settings.PrivacySecurity.lockApp
        case .callingConstantBitRate:
            return Settings.Vbr.title
        case .disableLinkPreviews:
            return Settings.PrivacySecurity.DisableLinkPreviews.title

            // personal information - Analytics
        case .disableCrashSharing:
            return Settings.PrivacyCrash.title
        case .disableAnalyticsSharing:
            return Settings.PrivacyAnalytics.title
        case .receiveNewsAndOffers:
            return Settings.ReceiveNewsAndOffers.title
        case .readReceiptsEnabled:
            return Settings.EnableReadReceipts.title
        case .encryptMessagesAtRest:
            return Settings.EncryptMessagesAtRest.title
        }
    }
}
