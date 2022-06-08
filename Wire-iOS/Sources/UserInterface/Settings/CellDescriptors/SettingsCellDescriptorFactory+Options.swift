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
import LocalAuthentication
import UIKit
import WireSyncEngine
import WireCommonComponents

extension SettingsCellDescriptorFactory {

    // MARK: - Options Group
    var optionsGroup: SettingsCellDescriptorType {
        let descriptors = [
            shareContactsDisabledSection,
            clearHistorySection,
            notificationVisibleSection,
            chatHeadsSection,
            soundAlertSection,
            callKitSection,
            muteCallSection,
            SecurityFlags.forceConstantBitRateCalls.isEnabled ? nil : VBRSection,
            soundsSection,
            externalAppsSection,
            popularDemandSendButtonSection,
            popularDemandDarkThemeSection,
            isAppLockAvailable ? appLockSection : nil,
            SecurityFlags.generateLinkPreviews.isEnabled ? linkPreviewSection : nil
        ].compactMap { $0 }

        return SettingsGroupCellDescriptor(
            items: descriptors,
            title: L10n.Localizable.Self.Settings.OptionsMenu.title,
            icon: .settingsOptions
        )
    }

    // MARK: - Sections
    private var shareContactsDisabledSection: SettingsSectionDescriptorType {
        let settingsButton = SettingsButtonCellDescriptor(
            title: L10n.Localizable.Self.Settings.PrivacyContactsMenu.SettingsButton.title,
            isDestructive: false,
            selectAction: { _ in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        })

        return SettingsSectionDescriptor(
            cellDescriptors: [settingsButton],
            header: L10n.Localizable.Self.Settings.PrivacyContactsSection.title,
            footer: L10n.Localizable.Self.Settings.PrivacyContactsMenu.DescriptionDisabled.title,
            visibilityAction: { _ in
                return AddressBookHelper.sharedHelper.isAddressBookAccessDisabled
        })
    }

    private var clearHistorySection: SettingsSectionDescriptorType {
        let clearHistoryButton = SettingsButtonCellDescriptor(
            title: L10n.Localizable.Self.Settings.Privacy.ClearHistory.title,
            isDestructive: false,
            selectAction: { _ in
                // erase history is not supported yet
        })

        return SettingsSectionDescriptor(
            cellDescriptors: [clearHistoryButton],
            header: .none,
            footer: L10n.Localizable.Self.Settings.Privacy.ClearHistory.subtitle,
            visibilityAction: { _ in return false }
        )
    }

    private var notificationVisibleSection: SettingsSectionDescriptorType {
        let notificationToggle = SettingsPropertyToggleCellDescriptor(
            settingsProperty: settingsPropertyFactory.property(.notificationContentVisible),
            inverse: true
        )

        return SettingsSectionDescriptor(
            cellDescriptors: [notificationToggle],
            header: L10n.Localizable.Self.Settings.Notifications.PushNotification.title,
            footer: L10n.Localizable.Self.Settings.Notifications.PushNotification.footer
        )
    }

    private var chatHeadsSection: SettingsSectionDescriptorType {
        let chatHeadsToggle = SettingsPropertyToggleCellDescriptor(
            settingsProperty: settingsPropertyFactory.property(.chatHeadsDisabled),
            inverse: true
        )

        return SettingsSectionDescriptor(
            cellDescriptors: [chatHeadsToggle],
            header: nil,
            footer: L10n.Localizable.Self.Settings.Notifications.ChatAlerts.footer
        )
    }

    private var soundAlertSection: SettingsSectionDescriptorType {
        return SettingsSectionDescriptor(cellDescriptors: [soundAlertGroup])
    }

    private var callKitSection: SettingsSectionDescriptorType {
        let callKitToggle = SettingsPropertyToggleCellDescriptor(
            settingsProperty: settingsPropertyFactory.property(.disableCallKit),
            inverse: true
        )

        return SettingsSectionDescriptor(
            cellDescriptors: [callKitToggle],
            header: L10n.Localizable.Self.Settings.Callkit.title,
            footer: L10n.Localizable.Self.Settings.Callkit.description,
            visibilityAction: .none
        )
    }

    private var muteCallSection: SettingsSectionDescriptorType {
        let muteCallToggle = SettingsPropertyToggleCellDescriptor(
            settingsProperty: settingsPropertyFactory.property(.muteIncomingCallsWhileInACall),
            inverse: false
        )

        return SettingsSectionDescriptor(
            cellDescriptors: [muteCallToggle],
            footer: L10n.Localizable.Self.Settings.MuteOtherCall.description,
            visibilityAction: .none
        )
    }

    private var VBRSection: SettingsSectionDescriptorType {
        let VBRToggle = SettingsPropertyToggleCellDescriptor(
            settingsProperty: settingsPropertyFactory.property(.callingConstantBitRate),
            inverse: true,
            identifier: "VBRSwitch"
        )

        return SettingsSectionDescriptor(
            cellDescriptors: [VBRToggle],
            header: .none,
            footer: L10n.Localizable.Self.Settings.Vbr.description,
            visibilityAction: .none
        )
    }

    private var soundsSection: SettingsSectionDescriptorType {

        let callSoundProperty = settingsPropertyFactory.property(.callSoundName)
        let callSoundGroup = soundGroupForSetting(
            callSoundProperty,
            title: callSoundProperty.propertyName.settingsPropertyLabelText,
            customSounds: ZMSound.ringtones,
            defaultSound: ZMSound.WireCall
        )

        let messageSoundProperty = settingsPropertyFactory.property(.messageSoundName)
        let messageSoundGroup = soundGroupForSetting(
            messageSoundProperty,
            title: messageSoundProperty.propertyName.settingsPropertyLabelText,
            customSounds: ZMSound.soundEffects,
            defaultSound: ZMSound.WireText
        )

        let pingSoundProperty = settingsPropertyFactory.property(.pingSoundName)
        let pingSoundGroup = soundGroupForSetting(
            pingSoundProperty,
            title: pingSoundProperty.propertyName.settingsPropertyLabelText,
            customSounds: ZMSound.soundEffects,
            defaultSound: ZMSound.WirePing
        )

        return SettingsSectionDescriptor(
            cellDescriptors: [callSoundGroup, messageSoundGroup, pingSoundGroup],
            header: L10n.Localizable.Self.Settings.SoundMenu.Sounds.title
        )
    }

    private var externalAppsSection: SettingsSectionDescriptorType? {
        var descriptors = [SettingsCellDescriptorType]()

        if BrowserOpeningOption.optionsAvailable {
            descriptors.append(browserOpeningGroup(for: settingsPropertyFactory.property(.browserOpeningOption)))
        }

        if MapsOpeningOption.optionsAvailable {
            descriptors.append(mapsOpeningGroup(for: settingsPropertyFactory.property(.mapsOpeningOption)))
        }

        if TweetOpeningOption.optionsAvailable {
            descriptors.append(twitterOpeningGroup(for: settingsPropertyFactory.property(.tweetOpeningOption)))
        }

        guard descriptors.count > 0 else {
            return nil
        }

        return SettingsSectionDescriptor(
            cellDescriptors: descriptors,
            header: L10n.Localizable.Self.Settings.ExternalApps.header
        )
    }

    private var popularDemandSendButtonSection: SettingsSectionDescriptorType {
        let sendButtonToggle = SettingsPropertyToggleCellDescriptor(
            settingsProperty: settingsPropertyFactory.property(.disableSendButton),
            inverse: true
        )

        return SettingsSectionDescriptor(
            cellDescriptors: [sendButtonToggle],
            header: L10n.Localizable.Self.Settings.PopularDemand.title,
            footer: L10n.Localizable.Self.Settings.PopularDemand.SendButton.footer
        )
    }

    private var popularDemandDarkThemeSection: SettingsSectionDescriptorType {
        let darkThemeSection = SettingsCellDescriptorFactory.darkThemeGroup(for: settingsPropertyFactory.property(.darkMode))

        return SettingsSectionDescriptor(
            cellDescriptors: [darkThemeSection],
            footer: L10n.Localizable.Self.Settings.PopularDemand.DarkMode.footer
        )
    }

    private var appLockSection: SettingsSectionDescriptorType {
        let appLockToggle = SettingsPropertyToggleCellDescriptor(settingsProperty: settingsPropertyFactory.property(.lockApp))

        appLockToggle.settingsProperty.enabled = !settingsPropertyFactory.isAppLockForced

        return SettingsSectionDescriptor(
            cellDescriptors: [appLockToggle],
            headerGenerator: { return nil },
            footerGenerator: { return self.appLockSectionSubtitle }
        )
    }

    private var linkPreviewSection: SettingsSectionDescriptorType {
        let linkPreviewToggle = SettingsPropertyToggleCellDescriptor(
            settingsProperty: settingsPropertyFactory.property(.disableLinkPreviews),
            inverse: true
        )

        return SettingsSectionDescriptor(
            cellDescriptors: [linkPreviewToggle],
            header: nil,
            footer: L10n.Localizable.Self.Settings.PrivacySecurity.DisableLinkPreviews.footer
        )
    }

    // MARK: - Helpers

    static func darkThemeGroup(for property: SettingsProperty) -> SettingsCellDescriptorType {
        let cells = SettingsColorScheme.allCases.map { option -> SettingsPropertySelectValueCellDescriptor in

            return SettingsPropertySelectValueCellDescriptor(
                settingsProperty: property,
                value: SettingsPropertyValue(option.rawValue),
                title: option.displayString
            )
        }

        let section = SettingsSectionDescriptor(cellDescriptors: cells.map { $0 as SettingsCellDescriptorType })
        let preview: PreviewGeneratorType = { _ in
            let value = property.value().value() as? Int
            guard let option = value.flatMap({ SettingsColorScheme(rawValue: $0) }) else { return .text(SettingsColorScheme.defaultPreference.displayString) }
            return .text(option.displayString)
        }
        return SettingsGroupCellDescriptor(items: [section], title: property.propertyName.settingsPropertyLabelText, identifier: nil, previewGenerator: preview)
    }

    func twitterOpeningGroup(for property: SettingsProperty) -> SettingsCellDescriptorType {
        let cells = TweetOpeningOption.availableOptions.map { option -> SettingsPropertySelectValueCellDescriptor in

            return SettingsPropertySelectValueCellDescriptor(
                settingsProperty: property,
                value: SettingsPropertyValue(option.rawValue),
                title: option.displayString
            )
        }

        let section = SettingsSectionDescriptor(cellDescriptors: cells.map { $0 as SettingsCellDescriptorType })
        let preview: PreviewGeneratorType = { _ in
            let value = property.value().value() as? Int
            guard let option = value.flatMap({ TweetOpeningOption(rawValue: $0) }) else { return .text(TweetOpeningOption.none.displayString) }
            return .text(option.displayString)
        }
        return SettingsGroupCellDescriptor(items: [section], title: property.propertyName.settingsPropertyLabelText, identifier: nil, previewGenerator: preview)
    }

    func mapsOpeningGroup(for property: SettingsProperty) -> SettingsCellDescriptorType {
        let cells = MapsOpeningOption.availableOptions.map { option -> SettingsPropertySelectValueCellDescriptor in

            return SettingsPropertySelectValueCellDescriptor(
                settingsProperty: property,
                value: SettingsPropertyValue(option.rawValue),
                title: option.displayString
            )
        }

        let section = SettingsSectionDescriptor(cellDescriptors: cells.map { $0 as SettingsCellDescriptorType }, header: nil, footer: L10n.Localizable.OpenLink.Maps.footer, visibilityAction: nil)
        let preview: PreviewGeneratorType = { _ in
            let value = property.value().value() as? Int
            guard let option = value.flatMap({ MapsOpeningOption(rawValue: $0) }) else { return .text(MapsOpeningOption.apple.displayString) }
            return .text(option.displayString)
        }
        return SettingsGroupCellDescriptor(items: [section], title: property.propertyName.settingsPropertyLabelText, identifier: nil, previewGenerator: preview)
    }

    func browserOpeningGroup(for property: SettingsProperty) -> SettingsCellDescriptorType {
        let cells = BrowserOpeningOption.availableOptions.map { option -> SettingsPropertySelectValueCellDescriptor in

            return SettingsPropertySelectValueCellDescriptor(
                settingsProperty: property,
                value: SettingsPropertyValue(option.rawValue),
                title: option.displayString
            )
        }

        let section = SettingsSectionDescriptor(cellDescriptors: cells.map { $0 as SettingsCellDescriptorType })
        let preview: PreviewGeneratorType = { _ in
            let value = property.value().value() as? Int
            guard let option = value.flatMap({ BrowserOpeningOption(rawValue: $0) }) else { return .text(BrowserOpeningOption.safari.displayString) }
            return .text(option.displayString)
        }
        return SettingsGroupCellDescriptor(items: [section], title: property.propertyName.settingsPropertyLabelText, identifier: nil, previewGenerator: preview)
    }

    static var appLockFormatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        formatter.zeroFormattingBehavior = .dropAll
        return formatter
    }

    private var appLockSectionSubtitle: String {
        let timeout = TimeInterval(settingsPropertyFactory.timeout)
        guard let amount = SettingsCellDescriptorFactory.appLockFormatter.string(from: timeout) else { return "" }
        let lockDescription = L10n.Localizable.Self.Settings.PrivacySecurity.LockApp.Subtitle.lockDescription(amount)
        let typeKey: String = {
            switch AuthenticationType.current {
            case .touchID: return L10n.Localizable.Self.Settings.PrivacySecurity.LockApp.Subtitle.touchId
            case .faceID: return L10n.Localizable.Self.Settings.PrivacySecurity.LockApp.Subtitle.faceId
            default: return L10n.Localizable.Self.Settings.PrivacySecurity.LockApp.Subtitle.none
            }
        }()

        var components = [lockDescription, typeKey.localized]

        if AuthenticationType.current == .unavailable {
            let reminderKey = L10n.Localizable.Self.Settings.PrivacySecurity.LockApp.Subtitle.customAppLockReminder
            components.append(reminderKey.localized)
        }

        return components.joined(separator: " ")
    }
}

// MARK: - Helpers
extension SettingsCellDescriptorFactory {
    // Encryption at rest will trigger its own variant of AppLock.
    var isAppLockAvailable: Bool {
        return !SecurityFlags.forceEncryptionAtRest.isEnabled && settingsPropertyFactory.isAppLockAvailable
    }
}
