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
    
    class DismissStepDelegate: NSObject, FormStepDelegate {
        var strongCapture: DismissStepDelegate?
        @objc func didCompleteFormStep(_ viewController: UIViewController!) {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: SettingsNavigationController.dismissNotificationName), object: nil)
            self.strongCapture = nil
        }
    }
    
    init(settingsPropertyFactory: SettingsPropertyFactory) {
        self.settingsPropertyFactory = settingsPropertyFactory
    }
    
    func rootSettingsGroup() -> SettingsControllerGeneratorType & SettingsInternalGroupCellDescriptorType {
        var topLevelElements = [self.accountGroup(), self.devicesGroup(), self.optionsGroup(), self.advancedGroup(), self.helpSection(), self.aboutSection()]
        
        if DeveloperMenuState.developerMenuEnabled() {
            topLevelElements = topLevelElements + [self.developerGroup()]
        }
        
        let topSection = SettingsSectionDescriptor(cellDescriptors: topLevelElements)

        return SettingsGroupCellDescriptor(items: [topSection], title: "self.settings".localized, style: .plain)
    }
    
    func accountGroup() -> SettingsCellDescriptorType {
        let nameElement = SettingsPropertyTextValueCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.profileName))
        
        let phoneElement: SettingsCellDescriptorType
        
        if let phoneNumber = ZMUser.selfUser().phoneNumber , !phoneNumber.isEmpty {
            phoneElement = SettingsInfoCellDescriptor(title: "self.settings.account_section.phone.title".localized, previewGenerator: { _ in
                return SettingsCellPreview.text(ZMUser.selfUser().phoneNumber)
            })
        }
        else {
            phoneElement = SettingsExternalScreenCellDescriptor(title: "self.add_phone_number".localized) { () -> (UIViewController?) in
                let addController = AddPhoneNumberViewController()
                addController.showsNavigationBar = false
                let stepDelegate = DismissStepDelegate()
                stepDelegate.strongCapture = stepDelegate
                
                addController.formStepDelegate = stepDelegate
                return addController
            }
        }
        
        
        let emailElement: SettingsCellDescriptorType
        
        if let emailAddress = ZMUser.selfUser().emailAddress , !emailAddress.isEmpty {
            emailElement = SettingsInfoCellDescriptor(title: "self.settings.account_section.email.title".localized, previewGenerator: { _ in
                return SettingsCellPreview.text(ZMUser.selfUser().emailAddress)
            })
        }
        else {
            emailElement = SettingsExternalScreenCellDescriptor(title: "self.add_email_password".localized) { () -> (UIViewController?) in
                let addEmailController = AddEmailPasswordViewController()
                addEmailController.showsNavigationBar = false
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
        let pictureElement = SettingsExternalScreenCellDescriptor(title: pictureText, isDestructive: false, presentationStyle: PresentationStyle.modal, presentationAction: { () -> (UIViewController?) in
            return ProfileSelfPictureViewController() as UIViewController
            }, previewGenerator: { (cell) -> SettingsCellPreview in
                guard let profileImageData = ZMUser.selfUser().imageSmallProfileData,
                let image = UIImage(data: profileImageData) else {
                    return .none
                }
                return .image(image)
        })
        
        let colorText = "self.settings.account_picture_group.color".localized
        let colorElement = SettingsExternalScreenCellDescriptor(title: colorText, isDestructive: false, presentationStyle: PresentationStyle.modal, presentationAction: { () -> (UIViewController?) in
            return AccentColorPickerController()
            }, previewGenerator: { (cell) -> SettingsCellPreview in
                return .color(ZMUser.selfUser().accentColor)
        })
        
        let appearanceSectionTitle = "self.settings.account_appearance_group.title".localized
        let appearanceSection = SettingsSectionDescriptor(cellDescriptors: [pictureElement, colorElement], header: appearanceSectionTitle)
        
        
        let resetPasswordTitle = "self.settings.password_reset_menu.title".localized
        let resetPassword = SettingsButtonCellDescriptor(title: resetPasswordTitle, isDestructive: false) { (cellDescriptor: SettingsCellDescriptorType) -> () in
            UIApplication.shared.openURL((NSURL.wr_passwordReset() as NSURL).wr_URLByAppendingLocaleParameter() as URL)
            Analytics.shared()?.tagResetPassword(true, from: ResetFromProfile)
        }
        
        
        var signOutSection: SettingsSectionDescriptor?
        if DeveloperMenuState.signOutEnabled() {
            let signOutButton = SettingsButtonCellDescriptor(title: "Sign out", isDestructive: false) { (cellDescriptor: SettingsCellDescriptorType) -> () in
                Settings.shared().reset()
                ZMUserSession.resetStateAndExit()
            }
            signOutSection = SettingsSectionDescriptor(cellDescriptors: [signOutButton], header: .none, footer: .none)
        }
        
        
        let deleteAccountButton = SettingsExternalScreenCellDescriptor(title: "self.settings.account_details.delete_account.title".localized, isDestructive: true, presentationStyle: .modal, presentationAction: { () -> (UIViewController?) in
            let alert = UIAlertController(title: "self.settings.account_details.delete_account.alert.title".localized, message: "self.settings.account_details.delete_account.alert.message".localized, preferredStyle: .alert)
            let actionCancel = UIAlertAction(title: "general.cancel".localized, style: .cancel, handler: { (alertAction: UIAlertAction) -> Void in
                
            })
            alert.addAction(actionCancel)
            let actionDelete = UIAlertAction(title: "general.ok".localized, style: .destructive, handler: { (alertAction: UIAlertAction) -> Void in
                ZMUserSession.shared().enqueueChanges({ () -> Void in
                    ZMUserSession.shared().initiateUserDeletion()
                })
            })
            alert.addAction(actionDelete)
            
            return alert
        })
        
        let actionsTitle = "self.settings.account_details.actions.title".localized
        let actionsSection = SettingsSectionDescriptor(cellDescriptors: [resetPassword, deleteAccountButton], header: actionsTitle, footer: .none)

        let items: [SettingsSectionDescriptorType]
        if let signOutSection = signOutSection {
            items = [nameAndDetailsSection, appearanceSection, actionsSection, signOutSection]
        }
        else {
            items = [nameAndDetailsSection, appearanceSection, actionsSection]
        }
        
        return SettingsGroupCellDescriptor(items: items, title: "self.settings.account_section".localized, icon: .settingsAccount)
    }

    
    func devicesGroup() -> SettingsCellDescriptorType {
        return SettingsExternalScreenCellDescriptor(title: "self.settings.privacy_analytics_menu.devices.title".localized,
            isDestructive: false,
            presentationStyle: PresentationStyle.navigation,
            identifier: type(of: self).settingsDevicesCellIdentifier,
            presentationAction: { () -> (UIViewController?) in
                Analytics.shared()?.tagSelfDeviceList()
                return ClientListViewController(clientsList: .none, credentials: .none, detailedView: true)
        }, icon: .settingsDevices)
    }
    
    func soundGroupForSetting(_ settingsProperty: SettingsProperty, title: String, callSound: Bool, fallbackSoundName: String, defaultSoundTitle : String = "self.settings.sound_menu.sounds.wire_sound".localized) -> SettingsCellDescriptorType {
        var items: [ZMSound?] = [.none]
        if callSound {
            items.append(contentsOf: ZMSound.ringtones.map { $0 as ZMSound? } )
        }
        else {
            items.append(contentsOf: ZMSound.allValues.filter { !ZMSound.ringtones.contains($0) }.map { $0 as ZMSound? } )
        }
        
        let cells: [SettingsPropertySelectValueCellDescriptor] = items.map {
            if let item = $0 {
                
                let playSoundAction: SettingsPropertySelectValueCellDescriptor.SelectActionType = { cellDescriptor in
                    item.playPreview()
                }
                
                return SettingsPropertySelectValueCellDescriptor(settingsProperty: settingsProperty, value: SettingsPropertyValue.string(value: item.rawValue), title: item.description, identifier: .none, selectAction: playSoundAction)
            }
            else {
                let playSoundAction: (SettingsPropertySelectValueCellDescriptor) -> () = { cellDescriptor in
                    ZMSound.playPreviewForURL(AVSMediaManager.url(forSound: fallbackSoundName))
                }
                
                return SettingsPropertySelectValueCellDescriptor(settingsProperty: settingsProperty, value: SettingsPropertyValue.none, title: defaultSoundTitle, identifier: .none, selectAction: playSoundAction)
            }
        }
        
        let section = SettingsSectionDescriptor(cellDescriptors: cells.map { $0 as SettingsCellDescriptorType }, header: "self.settings.sound_menu.ringtones.title".localized)
        
        let previewGenerator: PreviewGeneratorType = { cellDescriptor in
            let value = settingsProperty.value()
            
            if let stringValue = value.value() as? String,
                let enumValue = ZMSound(rawValue: stringValue) {
                return .text(enumValue.description)
            }
            else {
                return .text(defaultSoundTitle)
            }
        }
        
        return SettingsGroupCellDescriptor(items: [section], title: title, identifier: .none, previewGenerator: previewGenerator)
    }
    
    func advancedGroup() -> SettingsCellDescriptorType {
        let sendDataToWire = SettingsPropertyToggleCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.analyticsOptOut), inverse: true)
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
        
        let pushButton = SettingsExternalScreenCellDescriptor(title: pushTitle, isDestructive: false, presentationStyle: PresentationStyle.modal, presentationAction: { () -> (UIViewController?) in
            ZMUserSession.shared().resetPushTokens()
            let alert = UIAlertController(title: "self.settings.advanced.reset_push_token_alert.title".localized, message: "self.settings.advanced.reset_push_token_alert.message".localized, preferredStyle: .alert)
            weak var weakAlert = alert;
            alert.addAction(UIAlertAction(title: "general.ok".localized, style: .default, handler: { (alertAction: UIAlertAction) -> Void in
                if let alert = weakAlert {
                    alert.dismiss(animated: true, completion: nil)
                }
            }));
            return alert
        })
        
        let pushSection = SettingsSectionDescriptor(cellDescriptors: [pushButton], header: .none, footer: pushSectionSubtitle)  { (_) -> (Bool) in
            return true
        }

        let versionTitle =  "self.settings.advanced.version_technical_details.title".localized
        let versionCell = SettingsButtonCellDescriptor(title: versionTitle, isDestructive: false) { _ in
            UIApplication.shared.keyWindow?.rootViewController?.present(VersionInfoViewController(), animated: true, completion: .none)
        }

        let versionSection = SettingsSectionDescriptor(cellDescriptors: [versionCell])
        
        return SettingsGroupCellDescriptor(items: [sendUsageSection, troubleshootingSection, pushSection, versionSection], title: "self.settings.advanced.title".localized, icon: .settingsAdvanced)
    }
    
    func developerGroup() -> SettingsCellDescriptorType {
        let title = "self.settings.developer_options.title".localized
        
        let devController = SettingsExternalScreenCellDescriptor(title: "Logging") { () -> (UIViewController?) in
            return DeveloperOptionsController()
        }
        
        let diableAVSSetting = SettingsPropertyToggleCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.disableAVS))
        let diableUISetting = SettingsPropertyToggleCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.disableUI))
        let diableHockeySetting = SettingsPropertyToggleCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.disableHockey))
        let diableAnalyticsSetting = SettingsPropertyToggleCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.disableAnalytics))
        
        return SettingsGroupCellDescriptor(items: [SettingsSectionDescriptor(cellDescriptors: [devController, diableAVSSetting, diableUISetting, diableHockeySetting, diableAnalyticsSetting])], title: title, icon: .effectRobot)
    }
    
    func helpSection() -> SettingsCellDescriptorType {
        
        let supportButton = SettingsExternalScreenCellDescriptor(title: "self.help_center.support_website".localized, isDestructive: false, presentationStyle: .modal, presentationAction: { _ in
            Analytics.shared()?.tagHelp()
            return BrowserViewController(url: NSURL.wr_support().wr_URLByAppendingLocaleParameter() as URL!)
        }, previewGenerator: .none)
        
        let contactButton = SettingsExternalScreenCellDescriptor(title: "self.help_center.contact_support".localized, isDestructive: false, presentationStyle: .modal, presentationAction: { _ in
            return BrowserViewController(url: NSURL.wr_askSupport().wr_URLByAppendingLocaleParameter() as URL!)
        }, previewGenerator: .none)
        
        let helpSection = SettingsSectionDescriptor(cellDescriptors: [supportButton, contactButton])
        
        let reportButton = SettingsExternalScreenCellDescriptor(title: "self.report_abuse".localized, isDestructive: false, presentationStyle: .modal, presentationAction: { _ in
            return BrowserViewController(url: NSURL.wr_reportAbuse().wr_URLByAppendingLocaleParameter() as URL!)
        }, previewGenerator: .none)
        
        let reportSection = SettingsSectionDescriptor(cellDescriptors: [reportButton])
        
        return SettingsGroupCellDescriptor(items: [helpSection, reportSection], title: "self.help_center".localized, style: .grouped, identifier: .none, previewGenerator: .none, icon: .settingsSupport)
    }
    
    func aboutSection() -> SettingsCellDescriptorType {
        
        let privacyPolicyButton = SettingsExternalScreenCellDescriptor(title: "about.privacy.title".localized, isDestructive: false, presentationStyle: .modal, presentationAction: { _ in
            return BrowserViewController(url: (NSURL.wr_privacyPolicy() as NSURL).wr_URLByAppendingLocaleParameter() as URL!)
        }, previewGenerator: .none)
        let tosButton = SettingsExternalScreenCellDescriptor(title: "about.tos.title".localized, isDestructive: false, presentationStyle: .modal, presentationAction: { _ in
            return BrowserViewController(url: (NSURL.wr_termsOfServices() as NSURL).wr_URLByAppendingLocaleParameter() as URL!)
        }, previewGenerator: .none)
        let licenseButton = SettingsExternalScreenCellDescriptor(title: "about.license.title".localized, isDestructive: false, presentationStyle: .modal, presentationAction: { _ in
            return BrowserViewController(url: (NSURL.wr_licenseInformation() as NSURL).wr_URLByAppendingLocaleParameter() as URL!)
        }, previewGenerator: .none)

        let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildNumber = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String ?? "Unknown"

        var currentYear = NSCalendar.current.component(.year, from: Date())
        if currentYear < 2014 {
            currentYear = 2014
        }

        let version = String(format: "Version %@ (%@)", shortVersion, buildNumber)
        let copyrightInfo = String(format: "about.copyright.title".localized, currentYear)

        let linksSection = SettingsSectionDescriptor(
            cellDescriptors: [tosButton, privacyPolicyButton, licenseButton],
            header: nil,
            footer: "\n" + version + "\n" + copyrightInfo
        )
        
        let websiteButton = SettingsButtonCellDescriptor(title: "about.website.title".localized, isDestructive: false) { _ in
            UIApplication.shared.openURL((NSURL.wr_website() as NSURL).wr_URLByAppendingLocaleParameter() as URL)
        }

        let websiteSection = SettingsSectionDescriptor(cellDescriptors: [websiteButton])
        
        return SettingsGroupCellDescriptor(
            items: [websiteSection, linksSection],
            title: "self.about".localized,
            style: .grouped,
            identifier: .none,
            previewGenerator: .none,
            icon: .wireLogo
        )
    }
    
    // MARK: Subgroups
    
    func colorsSubgroup() -> SettingsSectionDescriptorType {
        let cellDescriptors = ZMAccentColor.all().map { (color) -> SettingsCellDescriptorType in
            let value = SettingsPropertyValue.number(value: Int(color.rawValue))
            return SettingsPropertySelectValueCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.accentColor), value: value, title: "", identifier: .none, selectAction: { _ in
                
                }, backgroundColor: color.color) as SettingsCellDescriptorType
        }
        let colorsSection = SettingsSectionDescriptor(cellDescriptors: cellDescriptors)
        return colorsSection
    }
}
