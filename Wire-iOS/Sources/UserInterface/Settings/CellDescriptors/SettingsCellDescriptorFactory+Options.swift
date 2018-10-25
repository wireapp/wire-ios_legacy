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


extension SettingsCellDescriptorFactory {

    func optionsGroup() -> SettingsCellDescriptorType {
        var cellDescriptors = [SettingsSectionDescriptorType]()
        
        let shareButtonTitleDisabled = "self.settings.privacy_contacts_menu.settings_button.title".localized
        let shareContactsDisabledSettingsButton = SettingsButtonCellDescriptor(title: shareButtonTitleDisabled, isDestructive: false, selectAction: { (descriptor: SettingsCellDescriptorType) -> () in
            UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
        }) { (descriptor: SettingsCellDescriptorType) -> (Bool) in
            if AddressBookHelper.sharedHelper.addressBookSearchPerformedAtLeastOnce {
                if AddressBookHelper.sharedHelper.isAddressBookAccessDisabled || AddressBookHelper.sharedHelper.isAddressBookAccessUnknown {
                    return true
                }
                else {
                    return false
                }
            }
            else {
                return true
            }
        }
        let headerText = "self.settings.privacy_contacts_section.title".localized
        let shareFooterDisabledText = "self.settings.privacy_contacts_menu.description_disabled.title".localized

        let shareContactsDisabledSection = SettingsSectionDescriptor(cellDescriptors: [shareContactsDisabledSettingsButton], header: headerText, footer: shareFooterDisabledText) { (descriptor: SettingsSectionDescriptorType) -> (Bool) in
            return AddressBookHelper.sharedHelper.isAddressBookAccessDisabled
        }
        
        cellDescriptors.append(shareContactsDisabledSection)

        let clearHistoryButton = SettingsButtonCellDescriptor(title: "self.settings.privacy.clear_history.title".localized, isDestructive: false) { (cellDescriptor: SettingsCellDescriptorType) -> () in
            // erase history is not supported yet
        }
        let subtitleText = "self.settings.privacy.clear_history.subtitle".localized

        let clearHistorySection = SettingsSectionDescriptor(cellDescriptors: [clearHistoryButton], header: .none, footer: subtitleText)  { (_) -> (Bool) in return false }
        cellDescriptors.append(clearHistorySection)
        
        let notificationHeader = "self.settings.notifications.push_notification.title".localized
        let notification = SettingsPropertyToggleCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.notificationContentVisible), inverse: true)
        let notificationFooter = "self.settings.notifications.push_notification.footer".localized
        let notificationVisibleSection = SettingsSectionDescriptor(cellDescriptors: [notification], header: notificationHeader, footer: notificationFooter)
        cellDescriptors.append(notificationVisibleSection)

        let chatHeads = SettingsPropertyToggleCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.chatHeadsDisabled), inverse: true)
        let chatHeadsFooter = "self.settings.notifications.chat_alerts.footer".localized
        let chatHeadsSection = SettingsSectionDescriptor(cellDescriptors: [chatHeads], header: nil, footer: chatHeadsFooter)
        cellDescriptors.append(chatHeadsSection)
        
        let soundAlert : SettingsCellDescriptorType = {
            let titleLabel = "self.settings.sound_menu.title".localized

            let soundAlertProperty = self.settingsPropertyFactory.property(.soundAlerts)

            let allAlerts = SettingsPropertySelectValueCellDescriptor(settingsProperty: soundAlertProperty,
                                                                      value: SettingsPropertyValue(AVSIntensityLevel.full.rawValue),
                                                                      title: "self.settings.sound_menu.all_sounds.title".localized)

            let someAlerts = SettingsPropertySelectValueCellDescriptor(settingsProperty: soundAlertProperty,
                                                                       value: SettingsPropertyValue(AVSIntensityLevel.some.rawValue),
                                                                       title: "self.settings.sound_menu.mute_while_talking.title".localized)

            let noneAlerts = SettingsPropertySelectValueCellDescriptor(settingsProperty: soundAlertProperty,
                                                                       value: SettingsPropertyValue(AVSIntensityLevel.none.rawValue),
                                                                       title: "self.settings.sound_menu.no_sounds.title".localized)

            let alertsSection = SettingsSectionDescriptor(cellDescriptors: [allAlerts, someAlerts, noneAlerts], header: titleLabel, footer: .none)

            let alertPreviewGenerator : PreviewGeneratorType = {
                let value = soundAlertProperty.value()
                guard let rawValue = value.value() as? NSNumber,
                    let intensityLevel = AVSIntensityLevel(rawValue: rawValue.uintValue) else { return .text($0.title) }

                switch intensityLevel {
                case .full:
                    return .text("self.settings.sound_menu.all_sounds.title".localized)
                case .some:
                    return .text("self.settings.sound_menu.mute_while_talking.title".localized)
                case .none:
                    return .text("self.settings.sound_menu.no_sounds.title".localized)
                }

            }
            return SettingsGroupCellDescriptor(items: [alertsSection], title: titleLabel, identifier: .none, previewGenerator: alertPreviewGenerator)
        }()

        let soundAlertSection = SettingsSectionDescriptor(cellDescriptors: [soundAlert])
        cellDescriptors.append(soundAlertSection)
        
        let callKitDescriptor = SettingsPropertyToggleCellDescriptor(settingsProperty: settingsPropertyFactory.property(.disableCallKit), inverse: true)
        let callKitHeader = "self.settings.callkit.title".localized
        let callKitDescription = "self.settings.callkit.description".localized
        let callKitSection = SettingsSectionDescriptor(cellDescriptors: [callKitDescriptor], header: callKitHeader, footer: callKitDescription, visibilityAction: .none)
        cellDescriptors.append(callKitSection)
        
        let VBRDescriptor = SettingsPropertyToggleCellDescriptor(
            settingsProperty: settingsPropertyFactory.property(.callingConstantBitRate),
            inverse: true,
            identifier: "VBRSwitch"
        )
        let VBRDescription = "self.settings.vbr.description".localized
        let VBRSection = SettingsSectionDescriptor(cellDescriptors: [VBRDescriptor], header: .none, footer: VBRDescription, visibilityAction: .none)
        cellDescriptors.append(VBRSection)
        
        let soundsHeader = "self.settings.sound_menu.sounds.title".localized

        let callSoundProperty = self.settingsPropertyFactory.property(.callSoundName)
        let callSoundGroup = self.soundGroupForSetting(callSoundProperty, title: SettingsPropertyLabelText(callSoundProperty.propertyName), customSounds: ZMSound.ringtones, defaultSound: ZMSound.WireCall)

        let messageSoundProperty = self.settingsPropertyFactory.property(.messageSoundName)
        let messageSoundGroup = self.soundGroupForSetting(messageSoundProperty, title: SettingsPropertyLabelText(messageSoundProperty.propertyName), customSounds: ZMSound.soundEffects, defaultSound: ZMSound.WireText)

        let pingSoundProperty = self.settingsPropertyFactory.property(.pingSoundName)
        let pingSoundGroup = self.soundGroupForSetting(pingSoundProperty, title: SettingsPropertyLabelText(pingSoundProperty.propertyName), customSounds: ZMSound.soundEffects, defaultSound: ZMSound.WirePing)

        let soundsSection = SettingsSectionDescriptor(cellDescriptors: [callSoundGroup, messageSoundGroup, pingSoundGroup], header: soundsHeader)
        cellDescriptors.append(soundsSection)
        
        var externalAppsDescriptors = [SettingsCellDescriptorType]()
        
        if BrowserOpeningOption.optionsAvailable {
            externalAppsDescriptors.append(browserOpeningGroup(for: settingsPropertyFactory.property(.browserOpeningOption)))
        }
        if MapsOpeningOption.optionsAvailable {
            externalAppsDescriptors.append(mapsOpeningGroup(for: settingsPropertyFactory.property(.mapsOpeningOption)))
        }
        if TweetOpeningOption.optionsAvailable {
            externalAppsDescriptors.append(twitterOpeningGroup(for: settingsPropertyFactory.property(.tweetOpeningOption)))
        }
        
        let externalAppsSection = SettingsSectionDescriptor(
            cellDescriptors: externalAppsDescriptors,
            header: "self.settings.external_apps.header".localized
        )
        
        if externalAppsDescriptors.count > 0 {
            cellDescriptors.append(externalAppsSection)
        }
        
        let sendButtonDescriptor = SettingsPropertyToggleCellDescriptor(settingsProperty: settingsPropertyFactory.property(.disableSendButton), inverse: true)

        var popularDemandDescriptors: [SettingsCellDescriptorType] = [sendButtonDescriptor]
        
        if UIDevice.current.userInterfaceIdiom != .pad {
            let darkThemeElement = SettingsPropertyToggleCellDescriptor(settingsProperty: settingsPropertyFactory.property(.darkMode))
            popularDemandDescriptors.insert(darkThemeElement, at: 0)
        }
        
        let byPopularDemandSection = SettingsSectionDescriptor(
            cellDescriptors: popularDemandDescriptors,
            header: "self.settings.popular_demand.title".localized,
            footer: "self.settings.popular_demand.send_button.footer".localized
        )
        
        cellDescriptors.append(byPopularDemandSection)
        
        let context: LAContext = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthentication, error: &error) {
            let lockApp = SettingsPropertyToggleCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.lockApp))
            let section = SettingsSectionDescriptor(cellDescriptors: [lockApp], header: .none, footer: appLockSectionSubtitle)
            cellDescriptors.append(section)
        }
        
        let linkPreviewDescriptor = SettingsPropertyToggleCellDescriptor(settingsProperty: settingsPropertyFactory.property(.disableLinkPreviews), inverse: true)
        let linkPreviewSection = SettingsSectionDescriptor(
            cellDescriptors: [linkPreviewDescriptor],
            header: nil,
            footer: "self.settings.privacy_security.disable_link_previews.footer".localized
        )
        
        cellDescriptors.append(linkPreviewSection)
        
        return SettingsGroupCellDescriptor(items: cellDescriptors, title: "self.settings.options_menu.title".localized, icon: .settingsOptions)
    }
    
    private var appLockSectionSubtitle: String {
        let lockDescription = "self.settings.privacy_security.lock_app.subtitle.lock_description".localized
        let typeKey: String = {
            switch AuthenticationType.current {
            case .none: return "self.settings.privacy_security.lock_app.subtitle.none"
            case .touchID: return "self.settings.privacy_security.lock_app.subtitle.touch_id"
            case .faceID: return "self.settings.privacy_security.lock_app.subtitle.face_id"
            }
        }()
        
        return lockDescription + " " + typeKey.localized
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
        return SettingsGroupCellDescriptor(items: [section], title: SettingsPropertyLabelText(property.propertyName), identifier: nil, previewGenerator: preview)
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
        return SettingsGroupCellDescriptor(items: [section], title: SettingsPropertyLabelText(property.propertyName), identifier: nil, previewGenerator: preview)
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
        return SettingsGroupCellDescriptor(items: [section], title: SettingsPropertyLabelText(property.propertyName), identifier: nil, previewGenerator: preview)
    }
    

}
