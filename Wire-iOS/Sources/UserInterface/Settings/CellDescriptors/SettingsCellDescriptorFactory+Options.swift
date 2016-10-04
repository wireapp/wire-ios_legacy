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


extension SettingsCellDescriptorFactory {

    func optionsGroup() -> SettingsCellDescriptorType {

        let shareButtonTitleDisabled = "self.settings.privacy_contacts_menu.settings_button.title".localized
        let shareContactsDisabledSettingsButton = SettingsButtonCellDescriptor(title: shareButtonTitleDisabled, isDestructive: false, selectAction: { (descriptor: SettingsCellDescriptorType) -> () in
            UIApplication.shared.openURL(URL(string:UIApplicationOpenSettingsURLString)!)
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

        let clearHistoryButton = SettingsButtonCellDescriptor(title: "self.settings.privacy.clear_history.title".localized, isDestructive: false) { (cellDescriptor: SettingsCellDescriptorType) -> () in
            // erase history is not supported yet
        }
        let subtitleText = "self.settings.privacy.clear_history.subtitle".localized

        let clearHistorySection = SettingsSectionDescriptor(cellDescriptors: [clearHistoryButton], header: .none, footer: subtitleText)  { (_) -> (Bool) in return false }

        let notificationHeader = "self.settings.notifications.push_notification.title".localized
        let notification = SettingsPropertyToggleCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.notificationContentVisible), inverse: true)
        let notificationFooter = "self.settings.notifications.push_notification.footer".localized
        let notificationVisibleSection = SettingsSectionDescriptor(cellDescriptors: [notification], header: notificationHeader, footer: notificationFooter)


        let chatHeads = SettingsPropertyToggleCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.chatHeadsDisabled), inverse: true)
        let chatHeadsFooter = "self.settings.notifications.chat_alerts.footer".localized
        let chatHeadsSection = SettingsSectionDescriptor(cellDescriptors: [chatHeads], header: nil, footer: chatHeadsFooter)

        let soundAlert : SettingsCellDescriptorType = {
            let titleLabel = "self.settings.sound_menu.title".localized

            let soundAlertProperty = self.settingsPropertyFactory.property(.soundAlerts)

            let allAlerts = SettingsPropertySelectValueCellDescriptor(settingsProperty: soundAlertProperty,
                                                                      value: SettingsPropertyValue.number(value: Int(AVSIntensityLevel.full.rawValue)),
                                                                      title: "self.settings.sound_menu.all_sounds.title".localized)

            let someAlerts = SettingsPropertySelectValueCellDescriptor(settingsProperty: soundAlertProperty,
                                                                       value: SettingsPropertyValue.number(value: Int(AVSIntensityLevel.some.rawValue)),
                                                                       title: "self.settings.sound_menu.mute_while_talking.title".localized)

            let noneAlerts = SettingsPropertySelectValueCellDescriptor(settingsProperty: soundAlertProperty,
                                                                       value: SettingsPropertyValue.number(value: Int(AVSIntensityLevel.none.rawValue)),
                                                                       title: "self.settings.sound_menu.no_sounds.title".localized)

            let alertsSection = SettingsSectionDescriptor(cellDescriptors: [allAlerts, someAlerts, noneAlerts], header: titleLabel, footer: .none)

            let alertPreviewGenerator : PreviewGeneratorType = {
                let value = soundAlertProperty.value()
                guard let rawValue = value.value() as? UInt,
                    let intensityLevel = AVSIntensityLevel(rawValue: rawValue) else { return .text($0.title) }

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


        let soundsHeader = "self.settings.sound_menu.sounds.title".localized

        let callSoundProperty = self.settingsPropertyFactory.property(.callSoundName)
        let callSoundGroup = self.soundGroupForSetting(callSoundProperty, title: SettingsPropertyLabelText(callSoundProperty.propertyName), callSound: true, fallbackSoundName: MediaManagerSoundRingingFromThemSound, defaultSoundTitle: "self.settings.sound_menu.sounds.wire_call".localized)

        let messageSoundProperty = self.settingsPropertyFactory.property(.messageSoundName)
        let messageSoundGroup = self.soundGroupForSetting(messageSoundProperty, title: SettingsPropertyLabelText(messageSoundProperty.propertyName), callSound: false, fallbackSoundName: MediaManagerSoundMessageReceivedSound, defaultSoundTitle: "self.settings.sound_menu.sounds.wire_message".localized)

        let pingSoundProperty = self.settingsPropertyFactory.property(.pingSoundName)
        let pingSoundGroup = self.soundGroupForSetting(pingSoundProperty, title: SettingsPropertyLabelText(pingSoundProperty.propertyName), callSound: false, fallbackSoundName: MediaManagerSoundIncomingKnockSound, defaultSoundTitle: "self.settings.sound_menu.sounds.wire_ping".localized)

        let soundsSection = SettingsSectionDescriptor(cellDescriptors: [callSoundGroup, messageSoundGroup, pingSoundGroup], header: soundsHeader)

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

        return SettingsGroupCellDescriptor(items: [shareContactsDisabledSection, clearHistorySection, notificationVisibleSection, chatHeadsSection, soundAlertSection, soundsSection, byPopularDemandSection], title: "self.settings.options_menu.title".localized, icon: .settingsOptions)
    }
}
