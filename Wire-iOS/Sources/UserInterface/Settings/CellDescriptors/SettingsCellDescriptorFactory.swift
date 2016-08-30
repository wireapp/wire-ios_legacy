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

@objc class SettingsCellDescriptorFactory: NSObject {
    static let settingsDevicesCellIdentifier: String = "devices"
    let settingsPropertyFactory: SettingsPropertyFactory
    
    init(settingsPropertyFactory: SettingsPropertyFactory) {
        self.settingsPropertyFactory = settingsPropertyFactory
    }
    
    func rootSettingsGroup() -> protocol<SettingsControllerGeneratorType, SettingsInternalGroupCellDescriptorType> {
        var topLevelElements = [self.accountGroup(), self.privacyAndSecurityGroup(), self.alertsGroup(), self.advancedGroup()]
        
        if DeveloperMenuState.developerMenuEnabled() {
            topLevelElements = topLevelElements + [self.developerGroup(), self.APSGroup()]
        }
        
        let topSection = SettingsSectionDescriptor(cellDescriptors: topLevelElements)

        return SettingsGroupCellDescriptor(items: [topSection], title: "self.settings".localized, style: .Plain)
    }
    
    func accountGroup() -> SettingsCellDescriptorType {
        let nameElement = SettingsPropertyTextValueCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.ProfileName))
        let nameSection = SettingsSectionDescriptor(cellDescriptors: [nameElement])
        
        let phoneLabel = SettingsPropertyTextValueCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.ProfilePhone))
        let emailLabel = SettingsPropertyTextValueCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.ProfileEmail))
        
        let headerText = "self.settings.account_details_group.title".localized
        let footerText = "self.settings.account_details_group.footer".localized
        let detailsSection = SettingsSectionDescriptor(cellDescriptors: [phoneLabel, emailLabel], header: headerText, footer: footerText) { (_) -> (Bool) in return false }
        
        let resetPasswordTitle = "self.settings.password_reset_menu.title".localized
        let resetPassword = SettingsButtonCellDescriptor(title: resetPasswordTitle, isDestructive: false) { (cellDescriptor: SettingsCellDescriptorType) -> () in
            UIApplication.sharedApplication().openURL(NSURL.wr_passwordResetURL().wr_URLByAppendingLocaleParameter())
            Analytics.shared()?.tagResetPassword(true, fromType: ResetFromProfile)
        }
        
        let resetPasswordSection = SettingsSectionDescriptor(cellDescriptors: [resetPassword])
        
        let signOutButton = SettingsButtonCellDescriptor(title: "Sign out", isDestructive: false) { (cellDescriptor: SettingsCellDescriptorType) -> () in
            // sign out is not supported yet
        }
        let signOutSection = SettingsSectionDescriptor(cellDescriptors: [signOutButton], header: .None, footer: .None) { (_) -> (Bool) in return false }

        let deleteAccountButton = SettingsExternalScreenCellDescriptor(title: "self.settings.account_details.delete_account.title".localized, isDestructive: true, presentationStyle: .Modal) { () -> (UIViewController?) in
            let alert = UIAlertController(title: "self.settings.account_details.delete_account.alert.title".localized, message: "self.settings.account_details.delete_account.alert.message".localized, preferredStyle: .Alert)
            let actionCancel = UIAlertAction(title: "general.cancel".localized, style: .Cancel, handler: { (alertAction: UIAlertAction) -> Void in
                
            })
            alert.addAction(actionCancel)
            let actionDelete = UIAlertAction(title: "general.ok".localized, style: .Destructive, handler: { (alertAction: UIAlertAction) -> Void in
                ZMUserSession.sharedSession().enqueueChanges({ () -> Void in
                    ZMUserSession.sharedSession().initiateUserDeletion()
                })
            })
            alert.addAction(actionDelete)
            
            return alert
        }
        
        let deleteSubtitle = "self.settings.account_details.delete_account.footer".localized
        let deleteSection = SettingsSectionDescriptor(cellDescriptors: [deleteAccountButton], header: .None, footer: deleteSubtitle)

        return SettingsGroupCellDescriptor(items: [nameSection, detailsSection, resetPasswordSection, signOutSection, deleteSection], title: "self.settings.account_section".localized)
    }
    
    func privacyAndSecurityGroup() -> SettingsCellDescriptorType {
        let shareButtonTitleDisabled = "self.settings.privacy_contacts_menu.settings_button.title".localized
        let shareContactsDisabledSettingsButton = SettingsButtonCellDescriptor(title: shareButtonTitleDisabled, isDestructive: false, selectAction: { (descriptor: SettingsCellDescriptorType) -> () in
                UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!)
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

        let devicesSectionTitle = "self.settings.privacy_analytics_menu.devices.title".localized
        let devicesSection = SettingsSectionDescriptor(cellDescriptors: [self.devicesGroup()], header: devicesSectionTitle, footer: .None)

        let reportButton = SettingsButtonCellDescriptor(title: "self.report_abuse".localized, isDestructive: false) { (cellDescriptor: SettingsCellDescriptorType) -> () in
            UIApplication.sharedApplication().openURL(NSURL.wr_reportAbuseURL().wr_URLByAppendingLocaleParameter())
        }
        
        let reportSection = SettingsSectionDescriptor(cellDescriptors: [reportButton])
        
        let clearHistoryButton = SettingsButtonCellDescriptor(title: "self.settings.privacy.clear_history.title".localized, isDestructive: false) { (cellDescriptor: SettingsCellDescriptorType) -> () in
            // erase history is not supported yet
        }
        let subtitleText = "self.settings.privacy.clear_history.subtitle".localized
        
        let clearHistorySection = SettingsSectionDescriptor(cellDescriptors: [clearHistoryButton], header: .None, footer: subtitleText)  { (_) -> (Bool) in return false }
        
        return SettingsGroupCellDescriptor(items: [shareContactsDisabledSection, devicesSection, reportSection, clearHistorySection], title: "self.settings.privacy_menu.title".localized)
    }
    
    func devicesGroup() -> SettingsCellDescriptorType {
        return SettingsExternalScreenCellDescriptor(title: "self.settings.privacy_analytics_menu.devices_button.title".localized,
            isDestructive: false,
            presentationStyle: PresentationStyle.Navigation,
            identifier: self.dynamicType.settingsDevicesCellIdentifier) { () -> (UIViewController?) in
                Analytics.shared()?.tagSelfDeviceList()
                return ClientListViewController(clientsList: .None, credentials: .None, detailedView: true)
        }
    }
    
    func alertsGroup() -> SettingsCellDescriptorType {
        
        let notificationHeader = "self.settings.notifications.push_notification.title".localized
        let notification = SettingsPropertyToggleCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.NotificationContentVisible), inverse: true)
        let notificationFooter = "self.settings.notifications.push_notification.footer".localized
        let notificationVisibleSection = SettingsSectionDescriptor(cellDescriptors: [notification], header: notificationHeader, footer: notificationFooter)

        
        let chatHeads = SettingsPropertyToggleCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.ChatHeadsDisabled), inverse: true)
        let chatHeadsFooter = "self.settings.notifications.chat_alerts.footer".localized
        let chatHeadsSection = SettingsSectionDescriptor(cellDescriptors: [chatHeads], header: nil, footer: chatHeadsFooter)
        
        let soundAlert : SettingsCellDescriptorType =  {
            let titleLabel = "self.settings.sound_menu.title".localized
            
            let soundAlertProperty = self.settingsPropertyFactory.property(.SoundAlerts)
            
            let allAlerts = SettingsPropertySelectValueCellDescriptor(settingsProperty: soundAlertProperty,
                                                                      value: SettingsPropertyValue.Number(value: Int(AVSIntensityLevel.Full.rawValue)),
                                                                      title: "self.settings.sound_menu.all_sounds.title".localized)
            
            let someAlerts = SettingsPropertySelectValueCellDescriptor(settingsProperty: soundAlertProperty,
                                                                       value: SettingsPropertyValue.Number(value: Int(AVSIntensityLevel.Some.rawValue)),
                                                                       title: "self.settings.sound_menu.mute_while_talking.title".localized)
            
            let noneAlerts = SettingsPropertySelectValueCellDescriptor(settingsProperty: soundAlertProperty,
                                                                       value: SettingsPropertyValue.Number(value: Int(AVSIntensityLevel.None.rawValue)),
                                                                       title: "self.settings.sound_menu.no_sounds.title".localized)
            
            let alertsSection = SettingsSectionDescriptor(cellDescriptors: [allAlerts, someAlerts, noneAlerts], header: titleLabel, footer: .None)
            
            let alertPreviewGenerator : SettingsGroupCellDescriptor.PreviewGeneratorType = {
                let value = soundAlertProperty.propertyValue
                guard let rawValue = value.value() as? UInt,
                    let intensityLevel = AVSIntensityLevel(rawValue: rawValue) else { return $0.title }
                
                switch intensityLevel {
                case .Full:
                    return "self.settings.sound_menu.all_sounds.title".localized
                case .Some:
                    return "self.settings.sound_menu.mute_while_talking.title".localized
                case .None:
                    return "self.settings.sound_menu.no_sounds.title".localized
                }
                
            }
            return SettingsGroupCellDescriptor(items: [alertsSection], title: titleLabel, identifier: .None, previewGenerator: alertPreviewGenerator)
        }()
        
        let soundAlertSection = SettingsSectionDescriptor(cellDescriptors: [soundAlert])

        
        let soundsHeader = "self.settings.sound_menu.sounds.title".localized
        
        let callSoundProperty = self.settingsPropertyFactory.property(.CallSoundName)
        let callSoundGroup = self.soundGroupForSetting(callSoundProperty, title: SettingsPropertyLabelText(callSoundProperty.propertyName), callSound: true, fallbackSoundName: MediaManagerSoundRingingFromThemSound, defaultSoundTitle: "self.settings.sound_menu.sounds.wire_call".localized)
        
        let messageSoundProperty = self.settingsPropertyFactory.property(.MessageSoundName)
        let messageSoundGroup = self.soundGroupForSetting(messageSoundProperty, title: SettingsPropertyLabelText(messageSoundProperty.propertyName), callSound: false, fallbackSoundName: MediaManagerSoundMessageReceivedSound, defaultSoundTitle: "self.settings.sound_menu.sounds.wire_message".localized)
        
        let pingSoundProperty = self.settingsPropertyFactory.property(.PingSoundName)
        let pingSoundGroup = self.soundGroupForSetting(pingSoundProperty, title: SettingsPropertyLabelText(pingSoundProperty.propertyName), callSound: false, fallbackSoundName: MediaManagerSoundIncomingKnockSound, defaultSoundTitle: "self.settings.sound_menu.sounds.wire_ping".localized)
        
        let soundsSection = SettingsSectionDescriptor(cellDescriptors: [callSoundGroup, messageSoundGroup, pingSoundGroup], header: soundsHeader)

        return SettingsGroupCellDescriptor(items: [notificationVisibleSection, chatHeadsSection, soundAlertSection, soundsSection], title: "self.settings.sound_menu.group.title".localized)
    }
    
    func soundGroupForSetting(settingsProperty: SettingsProperty, title: String, callSound: Bool, fallbackSoundName: String, defaultSoundTitle : String = "self.settings.sound_menu.sounds.wire_sound".localized) -> SettingsCellDescriptorType {
        var items: [ZMSound?] = [.None]
        if callSound {
            items.appendContentsOf(ZMSound.ringtones.map { $0 as ZMSound? } )
        }
        else {
            items.appendContentsOf(ZMSound.allValues.filter { !ZMSound.ringtones.contains($0) }.map { $0 as ZMSound? } )
        }
        
        let cells: [SettingsPropertySelectValueCellDescriptor] = items.map {
            if let item = $0 {
                
                let playSoundAction: SettingsPropertySelectValueCellDescriptor.SelectActionType = { cellDescriptor in
                    item.playPreview()
                }
                
                return SettingsPropertySelectValueCellDescriptor(settingsProperty: settingsProperty, value: SettingsPropertyValue.String(value: item.rawValue), title: item.description, identifier: .None, selectAction: playSoundAction)
            }
            else {
                let playSoundAction: (SettingsPropertySelectValueCellDescriptor) -> () = { cellDescriptor in
                    ZMSound.playPreviewForURL(AVSMediaManager.URLForSound(fallbackSoundName))
                }
                
                return SettingsPropertySelectValueCellDescriptor(settingsProperty: settingsProperty, value: SettingsPropertyValue.None, title: defaultSoundTitle, identifier: .None, selectAction: playSoundAction)
            }
        }
        
        let section = SettingsSectionDescriptor(cellDescriptors: cells.map { $0 as SettingsCellDescriptorType }, header: "self.settings.sound_menu.ringtones.title".localized)
        
        let previewGenerator: SettingsGroupCellDescriptor.PreviewGeneratorType = { cellDescriptor in
            let value = settingsProperty.propertyValue
            
            if let stringValue = value.value() as? String,
                let enumValue = ZMSound(rawValue: stringValue) {
                return enumValue.description
            }
            else {
                return defaultSoundTitle
            }
        }
        
        return SettingsGroupCellDescriptor(items: [section], title: title, identifier: .None, previewGenerator: previewGenerator)
    }
    
    func minionsGroup() -> SettingsCellDescriptorType {
        return SettingsGroupCellDescriptor(items: [], title: "Minions")
    }
    
    func advancedGroup() -> SettingsCellDescriptorType {
        let sendDataToWire = SettingsPropertyToggleCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.AnalyticsOptOut), inverse: true)
        let usageLabel = "self.settings.privacy_analytics_section.title".localized
        let usageInfo = "self.settings.privacy_analytics_menu.description.title".localized
        let sendUsageSection = SettingsSectionDescriptor(cellDescriptors: [sendDataToWire], header: usageLabel, footer: usageInfo)
        
        let troubleshootingSectionTitle = "self.settings.advanced.troubleshooting.title".localized
        let troubleshootingTitle = "self.settings.advanced.troubleshooting.submit_debug.title".localized
        let troubleshootingSectionSubtitle = "self.settings.advanced.troubleshooting.submit_debug.subtitle".localized
        let troubleshootingButton = SettingsExternalScreenCellDescriptor(title: troubleshootingTitle) { () -> (UIViewController?) in
            return SettingsTechnicalReportViewController()
        }
        
        let troubleshootingSection = SettingsSectionDescriptor(cellDescriptors: [troubleshootingButton], header: troubleshootingSectionTitle, footer: troubleshootingSectionSubtitle)
        
        let pushTitle = "self.settings.advanced.reset_push_token.title".localized
        let pushSectionSubtitle = "self.settings.advanced.reset_push_token.subtitle".localized
        
        let pushButton = SettingsExternalScreenCellDescriptor(title: pushTitle, isDestructive: false, presentationStyle: PresentationStyle.Modal) { () -> (UIViewController?) in
            ZMUserSession.sharedSession().resetPushTokens()
            let alert = UIAlertController(title: "self.settings.advanced.reset_push_token_alert.title".localized, message: "self.settings.advanced.reset_push_token_alert.message".localized, preferredStyle: .Alert)
            weak var weakAlert = alert;
            alert.addAction(UIAlertAction(title: "general.ok".localized, style: .Default, handler: { (alertAction: UIAlertAction) -> Void in
                if let alert = weakAlert {
                    alert.dismissViewControllerAnimated(true, completion: nil)
                }
            }));
            return alert
        }
        
        let pushSection = SettingsSectionDescriptor(cellDescriptors: [pushButton], header: .None, footer: pushSectionSubtitle)  { (_) -> (Bool) in
            return true
        }
        
        return SettingsGroupCellDescriptor(items: [sendUsageSection, troubleshootingSection, pushSection], title: "self.settings.advanced.title".localized)
    }
    
    func developerGroup() -> SettingsCellDescriptorType {
        let title = "self.settings.developer_options.title".localized
        
        let devController = SettingsExternalScreenCellDescriptor(title: "Logging") { () -> (UIViewController?) in
            return DevOptionsController()
        }
        
        let diableAVSSetting = SettingsPropertyToggleCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.DisableAVS))
        let diableUISetting = SettingsPropertyToggleCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.DisableUI))
        let diableHockeySetting = SettingsPropertyToggleCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.DisableHockey))
        let diableAnalyticsSetting = SettingsPropertyToggleCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.DisableAnalytics))
        
        return SettingsGroupCellDescriptor(items: [SettingsSectionDescriptor(cellDescriptors: [devController, diableAVSSetting, diableUISetting, diableHockeySetting, diableAnalyticsSetting])], title: title)
    }
    
    func APSGroup() -> SettingsCellDescriptorType {
        let title = "self.settings.apns_logging.title".localized
        
        return SettingsExternalScreenCellDescriptor(title: title) { () -> (UIViewController?) in
            let storyboard = UIStoryboard(name: "DeveloperAPNS", bundle:NSBundle(forClass: self.dynamicType))
            return storyboard.instantiateInitialViewController()
        }
    }
}
