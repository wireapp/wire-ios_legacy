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
import WireSyncEngine
import avs

class SettingsCellDescriptorFactory {
    static let settingsDevicesCellIdentifier: String = "devices"
    let settingsPropertyFactory: SettingsPropertyFactory
    let userRightInterfaceType: UserRightInterface.Type

    init(settingsPropertyFactory: SettingsPropertyFactory,
         userRightInterfaceType: UserRightInterface.Type = UserRight.self) {
        self.settingsPropertyFactory = settingsPropertyFactory
        self.userRightInterfaceType = userRightInterfaceType
    }

    func rootGroup(isTeamMember: Bool) -> SettingsControllerGeneratorType & SettingsInternalGroupCellDescriptorType {
        var rootElements: [SettingsCellDescriptorType] = []

        if ZMUser.selfUser().canManageTeam {
            rootElements.append(self.manageTeamCell())
        }

        rootElements.append(settingsGroup(isTeamMember: isTeamMember))
        #if MULTIPLE_ACCOUNTS_DISABLED
            // We skip "add account" cell
        #else
            rootElements.append(self.addAccountOrTeamCell())
        #endif
        let topSection = SettingsSectionDescriptor(cellDescriptors: rootElements)

        return SettingsGroupCellDescriptor(
            items: [topSection],
            title: L10n.Localizable.Self.profile,
            style: .plain)
    }

    func manageTeamCell() -> SettingsCellDescriptorType {
        return SettingsExternalScreenCellDescriptor(
            title: L10n.Localizable.Self.Settings.ManageTeam.title,
            isDestructive: false,
            presentationStyle: PresentationStyle.modal,
            identifier: nil,
            presentationAction: { () -> (UIViewController?) in
                 return BrowserViewController(url: URL.manageTeam(source: .settings))
            },
            previewGenerator: nil,
            icon: .team,
           accessoryViewMode: .alwaysHide)
    }

    func addAccountOrTeamCell() -> SettingsCellDescriptorType {

        let presentationAction: () -> UIViewController? = {

            if SessionManager.shared?.accountManager.accounts.count < SessionManager.shared?.maxNumberAccounts {
                SessionManager.shared?.addAccount()
            } else {
                if let controller = UIApplication.shared.topmostViewController(onlyFullScreen: false) {
                    let alert = UIAlertController(
                        title: L10n.Localizable.Self.Settings.AddAccount.Error.title,
                        message: L10n.Localizable.Self.Settings.AddAccount.Error.message,
                        alertAction: .ok(style: .cancel))
                    controller.present(alert, animated: true, completion: nil)
                }
            }

            return nil
        }

        return SettingsExternalScreenCellDescriptor(
            title: L10n.Localizable.Self.Settings.AddTeamOrAccount.title,
            isDestructive: false,
            presentationStyle: PresentationStyle.modal,
            identifier: nil,
            presentationAction: presentationAction,
            previewGenerator: nil,
            icon: .plus,
            accessoryViewMode: .alwaysHide)
    }

    func settingsGroup(isTeamMember: Bool) -> SettingsControllerGeneratorType & SettingsInternalGroupCellDescriptorType {
        var topLevelElements = [accountGroup(
            isTeamMember: isTeamMember),
            devicesCell(),
            optionsGroup,
            advancedGroup,
            helpSection(),
            aboutSection()]

        if Bundle.developerModeEnabled {
            topLevelElements.append(self.developerGroup())
        }

        let topSection = SettingsSectionDescriptor(cellDescriptors: topLevelElements)

        return SettingsGroupCellDescriptor(
            items: [topSection],
            title: L10n.Localizable.Self.settings,
            style: .plain,
            previewGenerator: .none,
            icon: .gear)
    }

    func devicesCell() -> SettingsCellDescriptorType {
        return SettingsExternalScreenCellDescriptor(
            title: L10n.Localizable.Self.Settings.PrivacyAnalyticsMenu.Devices.title,
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
           icon: .devices)
    }

    func soundGroupForSetting(_ settingsProperty: SettingsProperty, title: String, customSounds: [ZMSound], defaultSound: ZMSound) -> SettingsCellDescriptorType {
        let items: [ZMSound] = [ZMSound.None, defaultSound] + customSounds
        let previewPlayer: SoundPreviewPlayer = SoundPreviewPlayer(mediaManager: AVSMediaManager.sharedInstance())

        let cells: [SettingsPropertySelectValueCellDescriptor] = items.map { item in
            let playSoundAction: SettingsPropertySelectValueCellDescriptor.SelectActionType = { _ in

                switch settingsProperty.propertyName {
                case .callSoundName:
                    previewPlayer.playPreview(.ringingFromThemSound)
                case .pingSoundName:
                    previewPlayer.playPreview(.incomingKnockSound)
                case .messageSoundName:
                    previewPlayer.playPreview(.messageReceivedSound)
                default:
                    break
                }
            }

            let propertyValue = item == defaultSound ? SettingsPropertyValue.none : SettingsPropertyValue.string(value: item.rawValue)
            return SettingsPropertySelectValueCellDescriptor(settingsProperty: settingsProperty, value: propertyValue, title: item.descriptionLocalizationKey.localized, identifier: .none, selectAction: playSoundAction)
        }

        let section = SettingsSectionDescriptor(
            cellDescriptors: cells.map { $0 as SettingsCellDescriptorType },
            header: L10n.Localizable.Self.Settings.SoundMenu.Ringtones.title)

        let previewGenerator: PreviewGeneratorType = { _ in
            let value = settingsProperty.value()

            if let stringValue = value.value() as? String,
                let enumValue = ZMSound(rawValue: stringValue) {
                return .text(enumValue.descriptionLocalizationKey.localized)
            } else {
                return .text(defaultSound.descriptionLocalizationKey.localized)
            }
        }

        return SettingsGroupCellDescriptor(items: [section], title: title, identifier: .none, previewGenerator: previewGenerator)
    }

    func developerGroup() -> SettingsCellDescriptorType {
        var developerCellDescriptors: [SettingsCellDescriptorType] = []

        typealias ExternalScreen = SettingsExternalScreenCellDescriptor
        typealias Toggle = SettingsPropertyToggleCellDescriptor
        typealias Button = SettingsButtonCellDescriptor

        developerCellDescriptors.append(
            ExternalScreen(title: "Logging") { DeveloperOptionsController() }
        )

        developerCellDescriptors.append(
            Toggle(settingsProperty: settingsPropertyFactory.property(.enableBatchCollections))
        )

        developerCellDescriptors.append(
            Button(title: "Send broken message",
                   isDestructive: true,
                   selectAction: DebugActions.sendBrokenMessage)
        )

        developerCellDescriptors.append(
            Button(title: "First unread conversation (badge count)",
                   isDestructive: false,
                   selectAction: DebugActions.findUnreadConversationContributingToBadgeCount)
        )

        developerCellDescriptors.append(
            Button(title: "First unread conversation (back arrow count)",
                   isDestructive: false,
                   selectAction: DebugActions.findUnreadConversationContributingToBackArrowDot)
        )

        developerCellDescriptors.append(
            Button(title: "Delete invalid conversations",
                   isDestructive: false,
                   selectAction: DebugActions.deleteInvalidConversations)
        )

        developerCellDescriptors.append(SettingsShareDatabaseCellDescriptor())
        developerCellDescriptors.append(SettingsShareCryptoboxCellDescriptor())

        developerCellDescriptors.append(
            Button(title: "Reload user interface",
                   isDestructive: false,
                   selectAction: DebugActions.reloadUserInterface)
        )

        developerCellDescriptors.append(
            Button(title: "Re-calculate badge count",
                   isDestructive: false,
                   selectAction: DebugActions.recalculateBadgeCount)
        )

        developerCellDescriptors.append(
            Button(title: "Append N messages to the top conv (not sending)", isDestructive: true) { _ in
                DebugActions.askNumber(title: "Enter count of messages") { count in
                    DebugActions.appendMessagesInBatches(count: count)
                }
            }
        )

        developerCellDescriptors.append(
            Button(title: "Spam the top conv", isDestructive: true) { _ in
                DebugActions.askNumber(title: "Enter count of messages") { count in
                    DebugActions.spamWithMessages(amount: count)
                }
            }
        )

        developerCellDescriptors.append(
            ExternalScreen(title: "Show database statistics",
                           isDestructive: false,
                           presentationStyle: .navigation,
                           presentationAction: {  DatabaseStatisticsController() })
        )

        if !Analytics.shared.isOptedOut && !TrackingManager.shared.disableAnalyticsSharing {
            developerCellDescriptors.append(
                Button(title: "Reset call quality survey",
                       isDestructive: false,
                       selectAction: DebugActions.resetCallQualitySurveyMuteFilter)
            )
        }

        developerCellDescriptors.append(
            Button(title: "Generate test crash",
                   isDestructive: false,
                   selectAction: DebugActions.generateTestCrash)
        )

        developerCellDescriptors.append(
            Button(title: "Trigger slow sync",
                   isDestructive: false,
                   selectAction: DebugActions.triggerSlowSync)
        )

        developerCellDescriptors.append(
            Button(title: "What's my analytics id?",
                   isDestructive: false,
                   selectAction: DebugActions.showAnalyticsIdentifier)
        )

        developerCellDescriptors.append(
            Button(title: "What's the api version?",
                   isDestructive: false,
                   selectAction: DebugActions.showAPIVersionInfo)
        )

        return SettingsGroupCellDescriptor(items: [SettingsSectionDescriptor(cellDescriptors: developerCellDescriptors)],
                                           title: L10n.Localizable.`Self`.Settings.DeveloperOptions.title,
                                           icon: .robot)
    }

    func helpSection() -> SettingsCellDescriptorType {
        typealias HelpCenter = L10n.Localizable.Self.HelpCenter
        let supportButton = SettingsExternalScreenCellDescriptor(
            title: HelpCenter.supportWebsite,
            isDestructive: false, presentationStyle: .modal,
            presentationAction: {
            return BrowserViewController(url: URL.wr_support.appendingLocaleParameter)
        }, previewGenerator: .none)

        let contactButton = SettingsExternalScreenCellDescriptor(
            title: HelpCenter.contactSupport,
            isDestructive: false, presentationStyle: .modal,
            presentationAction: {
            return BrowserViewController(url: URL.wr_askSupport.appendingLocaleParameter)
        }, previewGenerator: .none)

        let helpSection = SettingsSectionDescriptor(cellDescriptors: [supportButton, contactButton])

        let reportButton = SettingsExternalScreenCellDescriptor(
            title: L10n.Localizable.Self.reportAbuse,
            isDestructive: false, presentationStyle: .modal,
            presentationAction: {
            return BrowserViewController(url: URL.wr_reportAbuse.appendingLocaleParameter)
        }, previewGenerator: .none)

        let reportSection = SettingsSectionDescriptor(cellDescriptors: [reportButton])

        return SettingsGroupCellDescriptor(
        items: [helpSection, reportSection],
        title: L10n.Localizable.Self.helpCenter,
         style: .grouped,
         identifier: .none,
         previewGenerator: .none,
         icon: .settingsSupport)
    }

    func aboutSection() -> SettingsCellDescriptorType {
        let privacyPolicyButton = SettingsExternalScreenCellDescriptor(
            title: L10n.Localizable.About.Privacy.title,
            isDestructive: false,
            presentationStyle: .modal,
            presentationAction: {
                return BrowserViewController(url: URL.wr_privacyPolicy.appendingLocaleParameter)
        }, previewGenerator: .none)
        let tosButton = SettingsExternalScreenCellDescriptor(
            title: L10n.Localizable.About.Tos.title,
            isDestructive: false,
            presentationStyle: .modal,
            presentationAction: {
                let url = URL.wr_termsOfServicesURL.appendingLocaleParameter
                return BrowserViewController(url: url)
        }, previewGenerator: .none)

        let shortVersion = Bundle.main.shortVersionString ?? "Unknown"
        let buildNumber = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String ?? "Unknown"

        var currentYear = NSCalendar.current.component(.year, from: Date())
        if currentYear < 2014 {
            currentYear = 2014
        }

        let version = String(format: "Version %@ (%@)", shortVersion, buildNumber)
        let copyrightInfo = String(format: L10n.Localizable.About.Copyright.title, currentYear)

        let linksSection = SettingsSectionDescriptor(
            cellDescriptors: [tosButton, privacyPolicyButton, licensesSection()],
            header: nil,
            footer: "\n" + version + "\n" + copyrightInfo
        )

        let websiteButton = SettingsExternalScreenCellDescriptor(
            title: L10n.Localizable.About.Website.title,
            isDestructive: false,
            presentationStyle: .modal,
            presentationAction: {
                return BrowserViewController(url: URL.wr_website.appendingLocaleParameter)
        }, previewGenerator: .none)

        let websiteSection = SettingsSectionDescriptor(cellDescriptors: [websiteButton])

        return SettingsGroupCellDescriptor(
            items: [websiteSection, linksSection],
            title: L10n.Localizable.Self.about,
            style: .grouped,
            identifier: .none,
            previewGenerator: .none,
            icon: .about
        )
    }

    func licensesSection() -> SettingsCellDescriptorType {
        guard let licenses = LicensesLoader.shared.loadLicenses() else {
            return webLicensesSection()
        }

        let childItems: [SettingsGroupCellDescriptor] = licenses.map { item in
            let projectCell = SettingsExternalScreenCellDescriptor(
                title: L10n.Localizable.About.License.openProjectButton,
                isDestructive: false,
                presentationStyle: .modal,
                presentationAction: {
                    return BrowserViewController(url: item.projectURL)
            }, previewGenerator: .none)
            let detailsSection = SettingsSectionDescriptor(
                cellDescriptors: [projectCell],
                header: L10n.Localizable.About.License.projectHeader,
                footer: nil)

            let licenseCell = SettingsStaticTextCellDescriptor(text: item.licenseText)
            let licenseSection = SettingsSectionDescriptor(
                cellDescriptors: [licenseCell],
                header: L10n.Localizable.About.License.licenseHeader,
                footer: nil)

            return SettingsGroupCellDescriptor(items: [detailsSection, licenseSection], title: item.name, style: .grouped)
        }

        let licensesSection = SettingsSectionDescriptor(cellDescriptors: childItems)
        return SettingsGroupCellDescriptor(
            items: [licensesSection],
            title: L10n.Localizable.About.License.title,
            style: .plain)

    }

    func webLicensesSection() -> SettingsCellDescriptorType {
        return SettingsExternalScreenCellDescriptor(
            title: L10n.Localizable.About.License.title,
            isDestructive: false,
            presentationStyle: .modal,
            presentationAction: {
                let url = URL.wr_licenseInformation.appendingLocaleParameter
                return BrowserViewController(url: url)
        }, previewGenerator: .none)
    }
}
