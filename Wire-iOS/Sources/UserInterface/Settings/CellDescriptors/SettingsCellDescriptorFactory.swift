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
    
    func rootGroup() -> SettingsControllerGeneratorType & SettingsInternalGroupCellDescriptorType {
        let rootElements = [self.devicesGroup(), self.settingsGroup(), self.inviteButton()]
        
        let topSection = SettingsSectionDescriptor(cellDescriptors: rootElements)
        
        return SettingsGroupCellDescriptor(items: [topSection], title: "self.profile".localized, style: .plain)
    }
    
    func inviteButton() -> SettingsCellDescriptorType {
        let inviteButtonDescriptor = InviteCellDescriptor(title: "self.settings.invite_friends.title".localized,
                                                          isDestructive: false,
                                                          presentationStyle: .modal,
                                                          presentationAction: { () -> (UIViewController?) in
                                                              return UIActivityViewController.shareInvite(completion: .none, logicalContext: .settings)
                                                          },
                                                          previewGenerator: .none,
                                                          icon: .megaphone)
        
        return inviteButtonDescriptor
        
    }
    
    func settingsGroup() -> SettingsControllerGeneratorType & SettingsInternalGroupCellDescriptorType {
        var topLevelElements = [self.accountGroup(), self.optionsGroup(), self.advancedGroup(), self.helpSection(), self.aboutSection()]
        
        if DeveloperMenuState.developerMenuEnabled() {
            topLevelElements = topLevelElements + [self.developerGroup()]
        }
        
        let topSection = SettingsSectionDescriptor(cellDescriptors: topLevelElements)

        return SettingsGroupCellDescriptor(items: [topSection], title: "self.settings".localized, style: .plain, previewGenerator: .none, icon: .gear)
    }
    
    func devicesGroup() -> SettingsCellDescriptorType {
        return SettingsExternalScreenCellDescriptor(title: "self.settings.privacy_analytics_menu.devices.title".localized,
            isDestructive: false,
            presentationStyle: PresentationStyle.navigation,
            identifier: type(of: self).settingsDevicesCellIdentifier,
            presentationAction: { () -> (UIViewController?) in
                Analytics.shared()?.tagSelfDeviceList()
                return ClientListViewController(clientsList: .none, credentials: .none, detailedView: true)
            },
            previewGenerator: { _ -> SettingsCellPreview in
                return SettingsCellPreview.badge(ZMUser.selfUser().clients.count)
            },
           icon: .settingsDevices)
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
        var items: [SettingsSectionDescriptor] = []
        
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
            ZMUserSession.shared()?.resetPushTokens()
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

        items.append(contentsOf: [sendUsageSection, troubleshootingSection, pushSection, versionSection])
        
        return SettingsGroupCellDescriptor(
            items: items,
            title: "self.settings.advanced.title".localized,
            icon: .settingsAdvanced
        )
    }
    
    func developerGroup() -> SettingsCellDescriptorType {
        let title = "self.settings.developer_options.title".localized
        var developerCellDescriptors: [SettingsCellDescriptorType] = []
        
        let devController = SettingsExternalScreenCellDescriptor(title: "Logging") { () -> (UIViewController?) in
            return DeveloperOptionsController()
        }
        
        let sendBrokenMessage = { (type: SettingsCellDescriptorType) -> Void in
            guard
                let userSession = ZMUserSession.shared(),
                let conversation = ZMConversationList.conversationsIncludingArchived(inUserSession: userSession).firstObject as? ZMConversation
            else {
                return
            }

            let builder = ZMExternal.builder()
            _ = builder?.setOtrKey("broken_key".data(using: .utf8))
            let genericMessage = ZMGenericMessage.genericMessage(pbMessage: builder!.build(), messageID: UUID().transportString(), expiresAfter: nil)
            
            userSession.enqueueChanges {
                conversation.append(genericMessage, expires: false, hidden: false)
            }
        }
        
        developerCellDescriptors.append(devController)
        
        let callingProtocolSetting = callingProtocolStrategyGroup(for: self.settingsPropertyFactory.property(.callingProtocolStrategy))
        developerCellDescriptors.append(callingProtocolSetting)
        let diableAVSSetting = SettingsPropertyToggleCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.disableAVS))
        developerCellDescriptors.append(diableAVSSetting)
        let diableUISetting = SettingsPropertyToggleCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.disableUI))
        developerCellDescriptors.append(diableUISetting)
        let diableHockeySetting = SettingsPropertyToggleCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.disableHockey))
        developerCellDescriptors.append(diableHockeySetting)
        let diableAnalyticsSetting = SettingsPropertyToggleCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.disableAnalytics))
        developerCellDescriptors.append(diableAnalyticsSetting)
        let enableBatchCollections = SettingsPropertyToggleCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.enableBatchCollections))
        developerCellDescriptors.append(enableBatchCollections)
        let sendBrokenMessageButton = SettingsButtonCellDescriptor(title: "Send broken message", isDestructive: true, selectAction: sendBrokenMessage)
        developerCellDescriptors.append(sendBrokenMessageButton)
        
        return SettingsGroupCellDescriptor(items: [SettingsSectionDescriptor(cellDescriptors:developerCellDescriptors)], title: title, icon: .effectRobot)
    }
    
    func callingProtocolStrategyGroup(for property: SettingsProperty) -> SettingsCellDescriptorType {
        let cells = CallingProtocolStrategy.allOptions.map { option -> SettingsPropertySelectValueCellDescriptor in
            
            return SettingsPropertySelectValueCellDescriptor(
                settingsProperty: property,
                value: SettingsPropertyValue(option.rawValue),
                title: option.displayString
            )
        }
        
        let section = SettingsSectionDescriptor(cellDescriptors: cells.map { $0 as SettingsCellDescriptorType })
        let preview: PreviewGeneratorType = { descriptor in
            guard case .number(let intValue) = property.value(),  let option = CallingProtocolStrategy(rawValue: UInt(intValue)) else {
                return .text(CallingProtocolStrategy.negotiate.displayString)
            }
            return .text(option.displayString)
        }
        return SettingsGroupCellDescriptor(items: [section], title: SettingsPropertyLabelText(property.propertyName), identifier: nil, previewGenerator: preview)
    }
    
    func helpSection() -> SettingsCellDescriptorType {
        
        let supportButton = SettingsExternalScreenCellDescriptor(title: "self.help_center.support_website".localized, isDestructive: false, presentationStyle: .modal, presentationAction: { _ in
            Analytics.shared()?.tagHelp()
            return BrowserViewController(url: NSURL.wr_support().wr_URLByAppendingLocaleParameter() as URL!)
        }, previewGenerator: .none)
        
        let contactButton = SettingsExternalScreenCellDescriptor(title: "self.help_center.contact_support".localized, isDestructive: false, presentationStyle: .modal, presentationAction: { _ in
            NSURL.wr_askSupport().wr_URLByAppendingLocaleParameter().open()
            return .none
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
            let value = SettingsPropertyValue(color.rawValue)
            return SettingsPropertySelectValueCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.accentColor), value: value, title: "", identifier: .none, selectAction: { _ in
                
                }, backgroundColor: color.color) as SettingsCellDescriptorType
        }
        let colorsSection = SettingsSectionDescriptor(cellDescriptors: cellDescriptors)
        return colorsSection
    }
}
