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
    static private var versionTapCount: UInt = 0
    
    class DismissStepDelegate: NSObject, FormStepDelegate {
        var strongCapture: DismissStepDelegate?
        @objc func didCompleteFormStep(viewController: UIViewController!) {
            NSNotificationCenter.defaultCenter().postNotificationName(SettingsNavigationController.dismissNotificationName, object: nil)
            self.strongCapture = nil
        }
    }
    
    init(settingsPropertyFactory: SettingsPropertyFactory) {
        self.settingsPropertyFactory = settingsPropertyFactory
    }
    
    func rootSettingsGroup() -> protocol<SettingsControllerGeneratorType, SettingsInternalGroupCellDescriptorType> {
        var topLevelElements = [self.accountGroup(), self.devicesGroup(), self.optionsGroup(), self.advancedGroup(), self.helpSection(), self.aboutSection()]
        
        if DeveloperMenuState.developerMenuEnabled() {
            topLevelElements = topLevelElements + [self.developerGroup()]
        }
        
        let topSection = SettingsSectionDescriptor(cellDescriptors: topLevelElements)

        return SettingsGroupCellDescriptor(items: [topSection], title: "self.settings".localized, style: .Plain)
    }
    
    func accountGroup() -> SettingsCellDescriptorType {
        let nameElement = SettingsPropertyTextValueCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.ProfileName))
        
        let phoneElement: SettingsCellDescriptorType
        
        if let phoneNumber = ZMUser.selfUser().phoneNumber where !phoneNumber.isEmpty {
            phoneElement = SettingsInfoCellDescriptor(title: "self.settings.account_section.phone.title".localized, previewGenerator: { _ in
                return .Text(ZMUser.selfUser().phoneNumber)
            })
        }
        else {
            phoneElement = SettingsExternalScreenCellDescriptor(title: "self.add_phone_number".localized) { () -> (UIViewController?) in
                let addController = AddPhoneNumberViewController()
                
                let stepDelegate = DismissStepDelegate()
                stepDelegate.strongCapture = stepDelegate
                
                addController.formStepDelegate = stepDelegate
                return addController
            }
        }
        
        
        let emailElement: SettingsCellDescriptorType
        
        if let emailAddress = ZMUser.selfUser().emailAddress where !emailAddress.isEmpty {
            emailElement = SettingsInfoCellDescriptor(title: "self.settings.account_section.email.title".localized, previewGenerator: { _ in
                return .Text(ZMUser.selfUser().emailAddress)
            })
        }
        else {
            emailElement = SettingsExternalScreenCellDescriptor(title: "self.add_email_password".localized) { () -> (UIViewController?) in
                let addEmailController = AddEmailPasswordViewController()
                
                let stepDelegate = DismissStepDelegate()
                stepDelegate.strongCapture = stepDelegate
                
                addEmailController.formStepDelegate = stepDelegate
                
                return addEmailController
            }
        }
        
        let headerText = "self.settings.account_details_group.title".localized
        let footerText = "self.settings.account_details_group.footer".localized
        let nameAndDetailsSection = SettingsSectionDescriptor(cellDescriptors: [nameElement, phoneElement, emailElement], header: headerText, footer: footerText)
        let pictureText = "self.settings.account_picture_group.picture".localized
        let pictureElement = SettingsExternalScreenCellDescriptor(title: pictureText, isDestructive: false, presentationStyle: PresentationStyle.Modal, presentationAction: { () -> (UIViewController?) in
            return ProfileSelfPictureViewController() as UIViewController
            }, previewGenerator: { (cell) -> SettingsCellPreview in
                guard let profileImageData = ZMUser.selfUser().imageSmallProfileData,
                let image = UIImage(data: profileImageData) else {
                    return .None
                }
                return .Image(image)
        })
        
        let colorText = "self.settings.account_picture_group.color".localized
        let colorElement = SettingsExternalScreenCellDescriptor(title: colorText, isDestructive: false, presentationStyle: PresentationStyle.Modal, presentationAction: { () -> (UIViewController?) in
            return AccentColorPickerController()
            }, previewGenerator: { (cell) -> SettingsCellPreview in
                return .Color(ZMUser.selfUser().accentColor)
        })
        
        let appearanceCells: [SettingsCellDescriptorType]
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            appearanceCells = [pictureElement, colorElement]
        }
        else {
            let darkThemeElement = SettingsPropertyToggleCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.DarkMode))
            appearanceCells = [pictureElement, colorElement, darkThemeElement]
        }
        
        let appearanceSectionTitle = "self.settings.account_appearance_group.title".localized
        let appearanceSection = SettingsSectionDescriptor(cellDescriptors: appearanceCells, header: appearanceSectionTitle)
        
        
        let resetPasswordTitle = "self.settings.password_reset_menu.title".localized
        let resetPassword = SettingsButtonCellDescriptor(title: resetPasswordTitle, isDestructive: false) { (cellDescriptor: SettingsCellDescriptorType) -> () in
            UIApplication.sharedApplication().openURL(NSURL.wr_passwordResetURL().wr_URLByAppendingLocaleParameter())
            Analytics.shared()?.tagResetPassword(true, fromType: ResetFromProfile)
        }
        
        let resetPasswordSection = SettingsSectionDescriptor(cellDescriptors: [resetPassword])
        
        var signOutSection: SettingsSectionDescriptor?
        if DeveloperMenuState.signOutEnabled() {
            let signOutButton = SettingsButtonCellDescriptor(title: "Sign out", isDestructive: false) { (cellDescriptor: SettingsCellDescriptorType) -> () in
                Settings.sharedSettings().reset()
                ZMUserSession.resetStateAndExit()
                exit(0)
            }
            signOutSection = SettingsSectionDescriptor(cellDescriptors: [signOutButton], header: .None, footer: .None)
        }
        
        
        let deleteAccountButton = SettingsExternalScreenCellDescriptor(title: "self.settings.account_details.delete_account.title".localized, isDestructive: true, presentationStyle: .Modal, presentationAction: { () -> (UIViewController?) in
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
        })
        
        let deleteSubtitle = "self.settings.account_details.delete_account.footer".localized
        let deleteSection = SettingsSectionDescriptor(cellDescriptors: [deleteAccountButton], header: .None, footer: deleteSubtitle)

        let items: [SettingsSectionDescriptorType]
        if let signOutSection = signOutSection {
            items = [nameAndDetailsSection, appearanceSection, resetPasswordSection, signOutSection, deleteSection]
        }
        else {
            items = [nameAndDetailsSection, appearanceSection, resetPasswordSection, deleteSection]
        }
        
        return SettingsGroupCellDescriptor(items: items, title: "self.settings.account_section".localized, icon: .SettingsAccount)
    }
    
    func optionsGroup() -> SettingsCellDescriptorType {
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

        let clearHistoryButton = SettingsButtonCellDescriptor(title: "self.settings.privacy.clear_history.title".localized, isDestructive: false) { (cellDescriptor: SettingsCellDescriptorType) -> () in
            // erase history is not supported yet
        }
        let subtitleText = "self.settings.privacy.clear_history.subtitle".localized
        
        let clearHistorySection = SettingsSectionDescriptor(cellDescriptors: [clearHistoryButton], header: .None, footer: subtitleText)  { (_) -> (Bool) in return false }
        
        let notificationHeader = "self.settings.notifications.push_notification.title".localized
        let notification = SettingsPropertyToggleCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.NotificationContentVisible), inverse: true)
        let notificationFooter = "self.settings.notifications.push_notification.footer".localized
        let notificationVisibleSection = SettingsSectionDescriptor(cellDescriptors: [notification], header: notificationHeader, footer: notificationFooter)
        
        
        let chatHeads = SettingsPropertyToggleCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.ChatHeadsDisabled), inverse: true)
        let chatHeadsFooter = "self.settings.notifications.chat_alerts.footer".localized
        let chatHeadsSection = SettingsSectionDescriptor(cellDescriptors: [chatHeads], header: nil, footer: chatHeadsFooter)
        
        let soundAlert : SettingsCellDescriptorType = {
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
            
            let alertPreviewGenerator : PreviewGeneratorType = {
                let value = soundAlertProperty.propertyValue
                guard let rawValue = value.value() as? UInt,
                    let intensityLevel = AVSIntensityLevel(rawValue: rawValue) else { return .Text($0.title) }
                
                switch intensityLevel {
                case .Full:
                    return .Text("self.settings.sound_menu.all_sounds.title".localized)
                case .Some:
                    return .Text("self.settings.sound_menu.mute_while_talking.title".localized)
                case .None:
                    return .Text("self.settings.sound_menu.no_sounds.title".localized)
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
        
        
        return SettingsGroupCellDescriptor(items: [shareContactsDisabledSection, clearHistorySection, notificationVisibleSection, chatHeadsSection, soundAlertSection, soundsSection], title: "self.settings.privacy_menu.title".localized, icon: .SettingsOptions)
    }
    
    func devicesGroup() -> SettingsCellDescriptorType {
        return SettingsExternalScreenCellDescriptor(title: "self.settings.privacy_analytics_menu.devices.title".localized,
            isDestructive: false,
            presentationStyle: PresentationStyle.Navigation,
            identifier: self.dynamicType.settingsDevicesCellIdentifier,
            presentationAction: { () -> (UIViewController?) in
                Analytics.shared()?.tagSelfDeviceList()
                return ClientListViewController(clientsList: .None, credentials: .None, detailedView: true)
        }, icon: .SettingsDevices)
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
        
        let previewGenerator: PreviewGeneratorType = { cellDescriptor in
            let value = settingsProperty.propertyValue
            
            if let stringValue = value.value() as? String,
                let enumValue = ZMSound(rawValue: stringValue) {
                return .Text(enumValue.description)
            }
            else {
                return .Text(defaultSoundTitle)
            }
        }
        
        return SettingsGroupCellDescriptor(items: [section], title: title, identifier: .None, previewGenerator: previewGenerator)
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
        
        let pushButton = SettingsExternalScreenCellDescriptor(title: pushTitle, isDestructive: false, presentationStyle: PresentationStyle.Modal, presentationAction: { () -> (UIViewController?) in
            ZMUserSession.sharedSession().resetPushTokens()
            let alert = UIAlertController(title: "self.settings.advanced.reset_push_token_alert.title".localized, message: "self.settings.advanced.reset_push_token_alert.message".localized, preferredStyle: .Alert)
            weak var weakAlert = alert;
            alert.addAction(UIAlertAction(title: "general.ok".localized, style: .Default, handler: { (alertAction: UIAlertAction) -> Void in
                if let alert = weakAlert {
                    alert.dismissViewControllerAnimated(true, completion: nil)
                }
            }));
            return alert
        })
        
        let pushSection = SettingsSectionDescriptor(cellDescriptors: [pushButton], header: .None, footer: pushSectionSubtitle)  { (_) -> (Bool) in
            return true
        }
        
        return SettingsGroupCellDescriptor(items: [sendUsageSection, troubleshootingSection, pushSection], title: "self.settings.advanced.title".localized, icon: .SettingsAdvanced)
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
        
        return SettingsGroupCellDescriptor(items: [SettingsSectionDescriptor(cellDescriptors: [devController, diableAVSSetting, diableUISetting, diableHockeySetting, diableAnalyticsSetting])], title: title, icon: .EffectRobot)
    }
    
    func helpSection() -> SettingsCellDescriptorType {
        
        let supportButton = SettingsExternalScreenCellDescriptor(title: "self.help_center.support_website".localized, isDestructive: false, presentationStyle: .Modal, presentationAction: { _ in
            Analytics.shared()?.tagHelp()
            return BrowserViewController(URL: NSURL.wr_supportURL().wr_URLByAppendingLocaleParameter())
        }, previewGenerator: .None)
        
        let contactButton = SettingsExternalScreenCellDescriptor(title: "self.help_center.contact_support".localized, isDestructive: false, presentationStyle: .Modal, presentationAction: { _ in
            return BrowserViewController(URL: NSURL.wr_askSupportURL().wr_URLByAppendingLocaleParameter())
        }, previewGenerator: .None)
        
        let helpSection = SettingsSectionDescriptor(cellDescriptors: [supportButton, contactButton])
        
        let reportButton = SettingsExternalScreenCellDescriptor(title: "self.report_abuse".localized, isDestructive: false, presentationStyle: .Modal, presentationAction: { _ in
            return BrowserViewController(URL: NSURL.wr_reportAbuseURL().wr_URLByAppendingLocaleParameter())
        }, previewGenerator: .None)
        
        let reportSection = SettingsSectionDescriptor(cellDescriptors: [reportButton])
        
        return SettingsGroupCellDescriptor(items: [helpSection, reportSection], title: "self.help_center".localized, style: .Grouped, identifier: .None, previewGenerator: .None, icon:  .SettingsSupport)
    }
    
    func aboutSection() -> SettingsCellDescriptorType {
        
        let privacyPolicyButton = SettingsExternalScreenCellDescriptor(title: "about.privacy.title".localized, isDestructive: false, presentationStyle: .Modal, presentationAction: { _ in
            return BrowserViewController(URL: NSURL.wr_privacyPolicyURL().wr_URLByAppendingLocaleParameter())
        }, previewGenerator: .None)
        let tosButton = SettingsExternalScreenCellDescriptor(title: "about.tos.title".localized, isDestructive: false, presentationStyle: .Modal, presentationAction: { _ in
            return BrowserViewController(URL: NSURL.wr_termsOfServicesURL().wr_URLByAppendingLocaleParameter())
        }, previewGenerator: .None)
        let licenseButton = SettingsExternalScreenCellDescriptor(title: "about.license.title".localized, isDestructive: false, presentationStyle: .Modal, presentationAction: { _ in
            return BrowserViewController(URL: NSURL.wr_licenseInformationURL().wr_URLByAppendingLocaleParameter())
        }, previewGenerator: .None)

        let linksSection = SettingsSectionDescriptor(cellDescriptors: [privacyPolicyButton, tosButton, licenseButton])
        
        let websiteButton = SettingsButtonCellDescriptor(title: "about.website.title".localized, isDestructive: false) { _ in
            UIApplication.sharedApplication().openURL(NSURL.wr_websiteURL().wr_URLByAppendingLocaleParameter())
        }
        
        
        let shortVersion = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildNumber = NSBundle.mainBundle().infoDictionary?[kCFBundleVersionKey as String] as? String ?? "Unknown"
        let version = String(format: "Version %@ (%@)", shortVersion, buildNumber)

        let currentDate = NSDate()
        var currentYear = NSCalendar.currentCalendar().component(.Year, fromDate:currentDate)
        if currentYear < 2014 {
            currentYear = 2014
        }
        
        let copyrightInfo = String(format: "about.copyright.title".localized, currentYear)

        let items: [SettingsSectionDescriptorType]
        if DeveloperMenuState.developerMenuEnabled() {
            let websiteSection = SettingsSectionDescriptor(cellDescriptors: [websiteButton])
            let versionCell = SettingsButtonCellDescriptor(title: version, isDestructive: false) { _ in
                SettingsCellDescriptorFactory.versionTapCount = SettingsCellDescriptorFactory.versionTapCount + 1
                
                if SettingsCellDescriptorFactory.versionTapCount % 3 == 0 {
                    let versionInfo = VersionInfoViewController()
                    
                    UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(versionInfo, animated: true, completion: .None)
                }
            }
            
            let infoSection = SettingsSectionDescriptor(cellDescriptors: [versionCell], header: .None, footer: copyrightInfo)
            items = [linksSection, websiteSection, infoSection]
        }
        else {
            let websiteSection = SettingsSectionDescriptor(cellDescriptors: [websiteButton], header: .None, footer: version + " " + copyrightInfo)
            items = [linksSection, websiteSection]
        }
        
        return SettingsGroupCellDescriptor(items: items, title: "self.about".localized, style: .Grouped, identifier: .None, previewGenerator: .None, icon:  .WireLogo)

    }
    
    // MARK: Subgroups
    
    func colorsSubgroup() -> SettingsSectionDescriptorType {
        let cellDescriptors = ZMAccentColor.all().map { (color) -> SettingsCellDescriptorType in
            let value = SettingsPropertyValue.Number(value: Int(color.rawValue))
            return SettingsPropertySelectValueCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.AccentColor), value: value, title: "", identifier: .None, selectAction: { _ in
                
                }, backgroundColor: color.color) as SettingsCellDescriptorType
        }
        let colorsSection = SettingsSectionDescriptor(cellDescriptors: cellDescriptors)
        return colorsSection
    }
}
