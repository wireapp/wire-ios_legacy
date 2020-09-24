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
            SecurityFlags.forceConstantBitRateCalls.isEnabled ? nil : VBRSection,
            conferenceCallingSection,
            soundsSection,
            externalAppsSection,
            popularDemandSendButtonSection,
            popularDemandDarkThemeSection,
            SecurityFlags.forceEncryptionAtRest.isEnabled ? nil : appLockSection,
            SecurityFlags.generateLinkPreviews.isEnabled ? linkPreviewSection : nil
        ].compactMap { $0 }
        
        return SettingsGroupCellDescriptor(
            items: descriptors,
            title: "self.settings.options_menu.title".localized,
            icon: .settingsOptions
        )
    }
    
    // MARK: - Sections
    private var shareContactsDisabledSection: SettingsSectionDescriptorType {
        let settingsButton = SettingsButtonCellDescriptor(
            title: "self.settings.privacy_contacts_menu.settings_button.title".localized,
            isDestructive: false,
            selectAction: { _ in
                UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
        })
        
        return SettingsSectionDescriptor(
            cellDescriptors: [settingsButton],
            header: "self.settings.privacy_contacts_section.title".localized,
            footer: "self.settings.privacy_contacts_menu.description_disabled.title".localized,
            visibilityAction: { _ in
                return AddressBookHelper.sharedHelper.isAddressBookAccessDisabled
        })
    }
    
    private var clearHistorySection: SettingsSectionDescriptorType {
        let clearHistoryButton = SettingsButtonCellDescriptor(
            title: "self.settings.privacy.clear_history.title".localized,
            isDestructive: false,
            selectAction: { (cellDescriptor: SettingsCellDescriptorType) -> Void in
                // erase history is not supported yet
        })
        
        return SettingsSectionDescriptor(
            cellDescriptors: [clearHistoryButton],
            header: .none,
            footer: "self.settings.privacy.clear_history.subtitle".localized,
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
            header: "self.settings.notifications.push_notification.title".localized,
            footer: "self.settings.notifications.push_notification.footer".localized
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
            footer: "self.settings.notifications.chat_alerts.footer".localized
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
            header:  "self.settings.callkit.title".localized,
            footer: "self.settings.callkit.description".localized,
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
            footer: "self.settings.vbr.description".localized,
            visibilityAction: .none
        )
    }
    
    private var conferenceCallingSection: SettingsSectionDescriptor {
        let betaToggle = SettingsPropertyToggleCellDescriptor(
            settingsProperty: settingsPropertyFactory.property(.enableConferenceCallingBeta),
            identifier: "Beta Toggle"
        )

        return SettingsSectionDescriptor(
            cellDescriptors: [betaToggle],
            header: "self.settings.advanced.conference_calling.title".localized,
            footer: "self.settings.advanced.conference_calling.subtitle".localized
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
            header:  "self.settings.sound_menu.sounds.title".localized
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
            header: "self.settings.external_apps.header".localized
        )
    }
    
    private var popularDemandSendButtonSection: SettingsSectionDescriptorType {
        let sendButtonToggle = SettingsPropertyToggleCellDescriptor(
            settingsProperty: settingsPropertyFactory.property(.disableSendButton),
            inverse: true
        )
        
        return SettingsSectionDescriptor(
            cellDescriptors: [sendButtonToggle],
            header: "self.settings.popular_demand.title".localized,
            footer: "self.settings.popular_demand.send_button.footer".localized
        )
    }
    
    private var popularDemandDarkThemeSection: SettingsSectionDescriptorType {
        let darkThemeSection = SettingsCellDescriptorFactory.darkThemeGroup(for: settingsPropertyFactory.property(.darkMode))
        
        return SettingsSectionDescriptor(
            cellDescriptors: [darkThemeSection],
            footer: "self.settings.popular_demand.dark_mode.footer".localized
        )
    }
    
    private var appLockSection: SettingsSectionDescriptorType {
        let appLockToggle = SettingsPropertyToggleCellDescriptor(settingsProperty: settingsPropertyFactory.property(.lockApp))
        appLockToggle.settingsProperty.enabled = !AppLock.rules.forceAppLock
        
        return SettingsSectionDescriptor(
            cellDescriptors: [appLockToggle],
            headerGenerator: { return nil },
            footerGenerator: { return SettingsCellDescriptorFactory.appLockSectionSubtitle },
            visibilityAction: { _ in
                return LAContext().canEvaluatePolicy(LAPolicy.deviceOwnerAuthentication, error: nil)
            }
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
            footer: "self.settings.privacy_security.disable_link_previews.footer".localized
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
        let preview: PreviewGeneratorType = { descriptor in
            let value = property.value().value() as? Int
            guard let option = value.flatMap ({ SettingsColorScheme(rawValue: $0) }) else { return .text(SettingsColorScheme.defaultPreference.displayString) }
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
        let preview: PreviewGeneratorType = { descriptor in
            let value = property.value().value() as? Int
            guard let option = value.flatMap ({ TweetOpeningOption(rawValue: $0) }) else { return .text(TweetOpeningOption.none.displayString) }
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

        let section = SettingsSectionDescriptor(cellDescriptors: cells.map { $0 as SettingsCellDescriptorType }, header: nil, footer: "open_link.maps.footer".localized, visibilityAction: nil)
        let preview: PreviewGeneratorType = { descriptor in
            let value = property.value().value() as? Int
            guard let option = value.flatMap ({ MapsOpeningOption(rawValue: $0) }) else { return .text(MapsOpeningOption.apple.displayString) }
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
        let preview: PreviewGeneratorType = { descriptor in
            let value = property.value().value() as? Int
            guard let option = value.flatMap ({ BrowserOpeningOption(rawValue: $0) }) else { return .text(BrowserOpeningOption.safari.displayString) }
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
    
    private static var appLockSectionSubtitle: String {
        let timeout = TimeInterval(AppLock.rules.appLockTimeout)
        guard let amount = SettingsCellDescriptorFactory.appLockFormatter.string(from: timeout) else { return "" }
        let lockDescription = "self.settings.privacy_security.lock_app.subtitle.lock_description".localized(args: amount)
        let typeKey: String = {
            switch AuthenticationType.current {
            case .touchID: return "self.settings.privacy_security.lock_app.subtitle.touch_id"
            case .faceID: return "self.settings.privacy_security.lock_app.subtitle.face_id"
            default: return "self.settings.privacy_security.lock_app.subtitle.none"
            }
        }()
        
        var components = [lockDescription, typeKey.localized]
        
        if AppLock.rules.useCustomCodeInsteadOfAccountPassword {
            let reminderKey = "self.settings.privacy_security.lock_app.subtitle.custom_app_lock_reminder"
            components.append(reminderKey.localized)
        }
        
        return components.joined(separator: " ")
    }
}
