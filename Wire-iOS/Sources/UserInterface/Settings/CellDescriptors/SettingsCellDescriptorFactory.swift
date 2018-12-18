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
import SafariServices

class SettingsCellDescriptorFactory {
    static let settingsDevicesCellIdentifier: String = "devices"
    let settingsPropertyFactory: SettingsPropertyFactory
    
    class DismissStepDelegate: NSObject {
        var strongCapture: DismissStepDelegate?
        // TODO: Remove
        @objc func didCompleteFormStep(_ viewController: UIViewController!) {
            NotificationCenter.default.post(name: NSNotification.Name.DismissSettings, object: nil)
            self.strongCapture = nil
        }
    }
    
    init(settingsPropertyFactory: SettingsPropertyFactory) {
        self.settingsPropertyFactory = settingsPropertyFactory
    }
    
    func rootGroup() -> SettingsControllerGeneratorType & SettingsInternalGroupCellDescriptorType {
        var rootElements: [SettingsCellDescriptorType] = []
        
        if ZMUser.selfUser().canManageTeam {
            rootElements.append(self.manageTeamCell())
        }
        
        rootElements.append(self.settingsGroup())
        #if MULTIPLE_ACCOUNTS_DISABLED
            // We skip "add account" cell
        #else
            rootElements.append(self.addAccountOrTeamCell())
        #endif
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
    
    func manageTeamCell() -> SettingsCellDescriptorType {
        return SettingsExternalScreenCellDescriptor(title: "self.settings.manage_team.title".localized,
                                                    isDestructive: false,
                                                    presentationStyle: PresentationStyle.modal,
                                                    identifier: nil,
                                                    presentationAction: { () -> (UIViewController?) in
                                                        Analytics.shared().tagOpenManageTeamURL()
                                                        return BrowserViewController(url: URL.manageTeam(source: .settings))
                                                    },
                                                    previewGenerator: nil,
                                                    icon: .team,
                                                    accessoryViewMode: .alwaysHide)
    }
    
    func addAccountOrTeamCell() -> SettingsCellDescriptorType {
        
        let presentationAction: () -> UIViewController? = {
            
            if SessionManager.shared?.accountManager.accounts.count < SessionManager.maxNumberAccounts {
                SessionManager.shared?.addAccount()
            }
            else {
                if let controller = UIApplication.shared.wr_topmostController(onlyFullScreen: false) {
                    let alert = UIAlertController(
                        title: "self.settings.add_account.error.title".localized,
                        message: "self.settings.add_account.error.message".localized,
                        cancelButtonTitle: "general.ok".localized
                    )
                    controller.present(alert, animated: true, completion: nil)
                }
            }
            
            return nil
        }
        
        return SettingsExternalScreenCellDescriptor(title: "self.settings.add_team_or_account.title".localized,
                                                    isDestructive: false,
                                                    presentationStyle: PresentationStyle.modal,
                                                    identifier: nil,
                                                    presentationAction: presentationAction,
                                                    previewGenerator: nil,
                                                    icon: .plus,
                                                    accessoryViewMode: .alwaysHide)
    }
    
    func settingsGroup() -> SettingsControllerGeneratorType & SettingsInternalGroupCellDescriptorType {
        var topLevelElements = [self.accountGroup(), self.devicesCell(), self.optionsGroup(), self.advancedGroup(), self.helpSection(), self.aboutSection()]
        
        if DeveloperMenuState.developerMenuEnabled() {
            topLevelElements.append(self.developerGroup())
        }
        
        let topSection = SettingsSectionDescriptor(cellDescriptors: topLevelElements)

        return SettingsGroupCellDescriptor(items: [topSection], title: "self.settings".localized, style: .plain, previewGenerator: .none, icon: .gear)
    }
    
    func devicesCell() -> SettingsCellDescriptorType {
        return SettingsExternalScreenCellDescriptor(title: "self.settings.privacy_analytics_menu.devices.title".localized,
            isDestructive: false,
            presentationStyle: PresentationStyle.navigation,
            identifier: type(of: self).settingsDevicesCellIdentifier,
            presentationAction: { () -> (UIViewController?) in
                return ClientListViewController(clientsList: .none,
                                                credentials: .none,
                                                detailedView: true)
            },
            previewGenerator: { _ -> SettingsCellPreview in
                return SettingsCellPreview.badge(ZMUser.selfUser().clients.count)
            },
           icon: .settingsDevices)
    }

    func soundGroupForSetting(_ settingsProperty: SettingsProperty, title: String, customSounds: [ZMSound], defaultSound: ZMSound) -> SettingsCellDescriptorType {
        let items: [ZMSound] = [ZMSound.None, defaultSound] + customSounds
        
        let cells: [SettingsPropertySelectValueCellDescriptor] = items.map { item in
            let playSoundAction: SettingsPropertySelectValueCellDescriptor.SelectActionType = { cellDescriptor in
                item.playPreview()
            }
            
            let propertyValue = item == defaultSound ? SettingsPropertyValue.none : SettingsPropertyValue.string(value: item.rawValue)
            return SettingsPropertySelectValueCellDescriptor(settingsProperty: settingsProperty, value: propertyValue, title: item.descriptionLocalizationKey.localized, identifier: .none, selectAction: playSoundAction)
        }
        
        let section = SettingsSectionDescriptor(cellDescriptors: cells.map { $0 as SettingsCellDescriptorType }, header: "self.settings.sound_menu.ringtones.title".localized)
        
        let previewGenerator: PreviewGeneratorType = { cellDescriptor in
            let value = settingsProperty.value()
            
            if let stringValue = value.value() as? String,
                let enumValue = ZMSound(rawValue: stringValue) {
                return .text(enumValue.descriptionLocalizationKey.localized)
            }
            else {
                return .text(defaultSound.descriptionLocalizationKey.localized)
            }
        }
        
        return SettingsGroupCellDescriptor(items: [section], title: title, identifier: .none, previewGenerator: previewGenerator)
    }

    func advancedGroup() -> SettingsCellDescriptorType {
        var items: [SettingsSectionDescriptor] = []
        
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
            ZMUserSession.shared()?.validatePushToken()
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
            let versionInfoViewController = VersionInfoViewController()
            var superViewController = UIApplication.shared.keyWindow?.rootViewController
            if let presentedViewController = superViewController?.presentedViewController {
                superViewController = presentedViewController
                versionInfoViewController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                versionInfoViewController.navigationController?.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            }
            superViewController?.present(versionInfoViewController, animated: true, completion: .none)
        }

        let versionSection = SettingsSectionDescriptor(cellDescriptors: [versionCell])

        items.append(contentsOf: [troubleshootingSection, pushSection, versionSection])
        
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
        
        developerCellDescriptors.append(devController)
        
        let enableBatchCollections = SettingsPropertyToggleCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.enableBatchCollections))
        developerCellDescriptors.append(enableBatchCollections)
        let sendBrokenMessageButton = SettingsButtonCellDescriptor(title: "Send broken message", isDestructive: true, selectAction: SettingsCellDescriptorFactory.sendBrokenMessage)
        developerCellDescriptors.append(sendBrokenMessageButton)
        let findUnreadBadgeConversationButton = SettingsButtonCellDescriptor(title: "First unread conversation (badge count)", isDestructive: false, selectAction: SettingsCellDescriptorFactory.findUnreadConversationContributingToBadgeCount)
        developerCellDescriptors.append(findUnreadBadgeConversationButton)
        let findUnreadBackArrowConversationButton = SettingsButtonCellDescriptor(title: "First unread conversation (back arrow count)", isDestructive: false, selectAction: SettingsCellDescriptorFactory.findUnreadConversationContributingToBackArrowDot)
        developerCellDescriptors.append(findUnreadBackArrowConversationButton)
        let shareDatabase = SettingsShareDatabaseCellDescriptor()
        developerCellDescriptors.append(shareDatabase)
        let shareCryptobox = SettingsShareCryptoboxCellDescriptor()
        developerCellDescriptors.append(shareCryptobox)
        let reloadUIButton = SettingsButtonCellDescriptor(title: "Reload user interface", isDestructive: false, selectAction: SettingsCellDescriptorFactory.reloadUserInterface)
        developerCellDescriptors.append(reloadUIButton)
        let appendManyMessages = SettingsButtonCellDescriptor(title: "Append N messages to the top conv (not sending)", isDestructive: true) { _ in
            
            self.requestNumber() { count in
                self.appendMessages(count: count)
            }
        }
        developerCellDescriptors.append(appendManyMessages)

        let showStatistics = SettingsExternalScreenCellDescriptor(title: "Show database statistics", isDestructive: false, presentationStyle: .navigation, presentationAction: {  DatabaseStatisticsController() })
        developerCellDescriptors.append(showStatistics)

        if !Analytics.shared().isOptedOut &&
            !TrackingManager.shared.disableCrashAndAnalyticsSharing {

            let resetSurveyMuteButton = SettingsButtonCellDescriptor(title: "Reset call quality survey", isDestructive: false, selectAction: SettingsCellDescriptorFactory.resetCallQualitySurveyMuteFilter)
            developerCellDescriptors.append(resetSurveyMuteButton)

        }

        return SettingsGroupCellDescriptor(items: [SettingsSectionDescriptor(cellDescriptors:developerCellDescriptors)], title: title, icon: .effectRobot)
    }
    
    func requestNumber(_ callback: @escaping (Int)->()) {
        guard let controllerToPresentOver = UIApplication.shared.wr_topmostController(onlyFullScreen: false) else { return }

        
        let controller = UIAlertController(
            title: "Enter count of messages",
            message: nil,
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "general.ok".localized, style: .default) { [controller] _ in
            callback(Int(controller.textFields?.first?.text ?? "0")!)
        }
        
        controller.addTextField()
        
        controller.addAction(.cancel { })
        controller.addAction(okAction)
        controllerToPresentOver.present(controller, animated: true, completion: nil)
    }
    
    func appendMessages(count: Int) {
        let userSession = ZMUserSession.shared()!
        let conversation = ZMConversationList.conversations(inUserSession: userSession).firstObject! as! ZMConversation
        let conversationId = conversation.objectID
        
        let syncContext = userSession.syncManagedObjectContext!
        syncContext.performGroupedBlock {
            let syncConversation = try! syncContext.existingObject(with: conversationId) as! ZMConversation
            let messages: [ZMClientMessage] = (0...count).map { i in
                let nonce = UUID()
                let genericMessage = ZMGenericMessage.message(content: ZMText.text(with: "Debugging message \(i): Append many messages to the top conversation; Append many messages to the top conversation;"), nonce: nonce)
                let clientMessage = ZMClientMessage(nonce: nonce, managedObjectContext: syncContext)
                clientMessage.add(genericMessage.data())
                clientMessage.sender = ZMUser.selfUser(in: syncContext)
                
                clientMessage.expire()
                clientMessage.linkPreviewState = .done
                
                return clientMessage
            }
            syncConversation.mutableMessages.addObjects(from: messages)
            userSession.syncManagedObjectContext.saveOrRollback()
        }
    }
    
    func helpSection() -> SettingsCellDescriptorType {
        
        let supportButton = SettingsExternalScreenCellDescriptor(title: "self.help_center.support_website".localized, isDestructive: false, presentationStyle: .modal, presentationAction: { 
            return BrowserViewController(url: URL.wr_support.appendingLocaleParameter)
        }, previewGenerator: .none)
        
        let contactButton = SettingsExternalScreenCellDescriptor(title: "self.help_center.contact_support".localized, isDestructive: false, presentationStyle: .modal, presentationAction: { 
            return BrowserViewController(url: URL.wr_askSupport.appendingLocaleParameter)
        }, previewGenerator: .none)
        
        let helpSection = SettingsSectionDescriptor(cellDescriptors: [supportButton, contactButton])
        
        let reportButton = SettingsExternalScreenCellDescriptor(title: "self.report_abuse".localized, isDestructive: false, presentationStyle: .modal, presentationAction: { 
            return BrowserViewController(url: URL.wr_reportAbuse.appendingLocaleParameter)
        }, previewGenerator: .none)
        
        let reportSection = SettingsSectionDescriptor(cellDescriptors: [reportButton])
        
        return SettingsGroupCellDescriptor(items: [helpSection, reportSection], title: "self.help_center".localized, style: .grouped, identifier: .none, previewGenerator: .none, icon: .settingsSupport)
    }
    
    func aboutSection() -> SettingsCellDescriptorType {
        
        let privacyPolicyButton = SettingsExternalScreenCellDescriptor(title: "about.privacy.title".localized, isDestructive: false, presentationStyle: .modal, presentationAction: { 
            return BrowserViewController(url: URL.wr_privacyPolicy.appendingLocaleParameter)
        }, previewGenerator: .none)
        let tosButton = SettingsExternalScreenCellDescriptor(title: "about.tos.title".localized, isDestructive: false, presentationStyle: .modal, presentationAction: { 
            let url = URL.wr_termsOfServicesURL(forTeamAccount: ZMUser.selfUser().hasTeam).appendingLocaleParameter
            return BrowserViewController(url: url)
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
            cellDescriptors: [tosButton, privacyPolicyButton, licensesSection()],
            header: nil,
            footer: "\n" + version + "\n" + copyrightInfo
        )
        
        let websiteButton = SettingsExternalScreenCellDescriptor(title: "about.website.title".localized, isDestructive: false, presentationStyle: .modal, presentationAction: { 
            return BrowserViewController(url: URL.wr_website.appendingLocaleParameter)
        }, previewGenerator: .none)

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

    func licensesSection() -> SettingsCellDescriptorType {
        guard let licenses = LicensesLoader.shared.loadLicenses() else {
            return webLicensesSection()
        }

        let childItems: [SettingsGroupCellDescriptor] = licenses.map { item in
            let projectCell = SettingsExternalScreenCellDescriptor(title: "about.license.open_project_button".localized, isDestructive: false, presentationStyle: .modal, presentationAction: {
                return BrowserViewController(url: item.projectURL)
            }, previewGenerator: .none)
            let detailsSection = SettingsSectionDescriptor(cellDescriptors: [projectCell], header: "about.license.project_header".localized, footer: nil)

            let licenseCell = SettingsStaticTextCellDescriptor(text: item.licenseText)
            let licenseSection = SettingsSectionDescriptor(cellDescriptors: [licenseCell], header: "about.license.license_header".localized, footer: nil)

            return SettingsGroupCellDescriptor(items: [detailsSection, licenseSection], title: item.name, style: .grouped)
        }

        let licensesSection = SettingsSectionDescriptor(cellDescriptors: childItems)
        return SettingsGroupCellDescriptor(items: [licensesSection], title: "about.license.title".localized, style: .plain)

    }

    func webLicensesSection() -> SettingsCellDescriptorType {
        return SettingsExternalScreenCellDescriptor(title: "about.license.title".localized, isDestructive: false, presentationStyle: .modal, presentationAction: {
            let url = URL.wr_licenseInformation.appendingLocaleParameter
            return BrowserViewController(url: url)
        }, previewGenerator: .none)
    }
    
    // MARK: Actions
    
    /// Check if there is any unread conversation, if there is, show an alert with the name and ID of the conversation
    private static func findUnreadConversationContributingToBadgeCount(_ type: SettingsCellDescriptorType) {
        guard let userSession = ZMUserSession.shared() else { return }
        let predicate = ZMConversation.predicateForConversationConsideredUnread()!
        
        guard let controller = UIApplication.shared.wr_topmostController(onlyFullScreen: false) else { return }
        let alert = UIAlertController(title: nil, message: "", preferredStyle: .alert)

        if let convo = (ZMConversationList.conversations(inUserSession: userSession) as! [ZMConversation])
            .first(where: { predicate.evaluate(with: $0) })
        {
            alert.message = ["Found an unread conversation:",
                       "\(convo.displayName)",
                        "<\(convo.remoteIdentifier?.uuidString ?? "n/a")>"
                ].joined(separator: "\n")
            alert.addAction(UIAlertAction(title: "Copy", style: .default, handler: { _ in
                UIPasteboard.general.string = alert.message
            }))

        } else {
            alert.message = "No unread conversation"
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        controller.present(alert, animated: false)
    }
    
    /// Check if there is any unread conversation, if there is, show an alert with the name and ID of the conversation
    private static func findUnreadConversationContributingToBackArrowDot(_ type: SettingsCellDescriptorType) {
        guard let userSession = ZMUserSession.shared() else { return }
        let predicate = ZMConversation.predicateForConversationConsideredUnreadExcludingSilenced()!
        
        guard let controller = UIApplication.shared.wr_topmostController(onlyFullScreen: false) else { return }
        let alert = UIAlertController(title: nil, message: "", preferredStyle: .alert)
        
        if let convo = (ZMConversationList.conversations(inUserSession: userSession) as! [ZMConversation])
            .first(where: predicate.evaluate)
        {
            alert.message = ["Found an unread conversation:",
                             "\(convo.displayName)",
                "<\(convo.remoteIdentifier?.uuidString ?? "n/a")>"
                ].joined(separator: "\n")
            alert.addAction(UIAlertAction(title: "Copy", style: .default, handler: { _ in
                UIPasteboard.general.string = alert.message
            }))
            
        } else {
            alert.message = "No unread conversation"
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        controller.present(alert, animated: false)
    }
    
    /// Sends a message that will fail to decode on every other device, on the first conversation of the list
    private static func sendBrokenMessage(_ type: SettingsCellDescriptorType) {
        guard
            let userSession = ZMUserSession.shared(),
            let conversation = ZMConversationList.conversationsIncludingArchived(inUserSession: userSession).firstObject as? ZMConversation
            else {
                return
        }
        
        let builder = ZMExternalBuilder()
        _ = builder.setOtrKey("broken_key".data(using: .utf8))
        let genericMessage = ZMGenericMessage.message(content: builder.build())
        
        userSession.enqueueChanges {
            conversation.appendClientMessage(with: genericMessage, expires: false, hidden: false)
        }
    }
    
    private static func reloadUserInterface(_ type: SettingsCellDescriptorType) {
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController as? AppRootViewController else {
            return
        }
        
        rootViewController.reload()
    }

    private static func resetCallQualitySurveyMuteFilter(_ type: SettingsCellDescriptorType) {
        guard let controller = UIApplication.shared.wr_topmostController(onlyFullScreen: false) else { return }

        CallQualityController.resetSurveyMuteFilter()

        let alert = UIAlertController(title: "Success",
                                      message: "The call quality survey will be displayed after the next call.",
                                      cancelButtonTitle: "OK")

        controller.present(alert, animated: true)
    }
}


