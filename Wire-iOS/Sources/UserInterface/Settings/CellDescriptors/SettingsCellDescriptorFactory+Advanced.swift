//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import UIKit
import WireSyncEngine

extension SettingsCellDescriptorFactory {

    // MARK: - Advanced group
    var advancedGroup: SettingsCellDescriptorType {
        var items = [SettingsSectionDescriptor]()

        items.append(contentsOf: [
            troubleshootingSection,
            debuggingToolsSection,
            pushSection,
            versionSection
        ])

        return SettingsGroupCellDescriptor(
            items: items,
            title: L10n.Localizable.Self.Settings.Advanced.title,
            icon: .settingsAdvanced
        )
    }

    // MARK: - Sections
    private var troubleshootingSection: SettingsSectionDescriptor {
        let submitDebugButton = SettingsExternalScreenCellDescriptor(
            title: L10n.Localizable.Self.Settings.Advanced.Troubleshooting.SubmitDebug.title,
            presentationAction: { () -> (UIViewController?) in
                return SettingsTechnicalReportViewController()
        })

        return SettingsSectionDescriptor(
            cellDescriptors: [submitDebugButton],
            header: L10n.Localizable.Self.Settings.Advanced.Troubleshooting.title,
            footer: L10n.Localizable.Self.Settings.Advanced.Troubleshooting.SubmitDebug.subtitle
        )
    }

    private var pushSection: SettingsSectionDescriptor {
        let pushButton = SettingsExternalScreenCellDescriptor(
            title: L10n.Localizable.Self.Settings.Advanced.ResetPushToken.title,
            isDestructive: false,
            presentationStyle: PresentationStyle.modal,
            presentationAction: { () -> (UIViewController?) in
                ZMUserSession.shared()?.validatePushToken()
                return self.pushButtonAlertController
        })

        return SettingsSectionDescriptor(
            cellDescriptors: [pushButton],
            header: .none,
            footer: L10n.Localizable.Self.Settings.Advanced.ResetPushToken.subtitle,
            visibilityAction: { _ in
                return true
        })
    }

    private var versionSection: SettingsSectionDescriptor {
        let versionCell = SettingsButtonCellDescriptor(
            title: L10n.Localizable.Self.Settings.Advanced.VersionTechnicalDetails.title,
            isDestructive: false,
            selectAction: presentVersionAction
        )

        return SettingsSectionDescriptor(cellDescriptors: [versionCell])
    }

    private var debuggingToolsSection: SettingsSectionDescriptor {

        let findUnreadConversationSection = SettingsSectionDescriptor(cellDescriptors: [
            SettingsButtonCellDescriptor(
                title: L10n.Localizable.Self.Settings.Advanced.DebuggingTools.FirstUnreadConversation.title,
                isDestructive: false,
                selectAction: DebugActions.findUnreadConversationContributingToBadgeCount
            ),
            SettingsButtonCellDescriptor(
                title: L10n.Localizable.Self.Settings.Advanced.DebuggingTools.ShowUserId.title,
                isDestructive: false,
                selectAction: DebugActions.showUserId
            ),
            SettingsButtonCellDescriptor(
                title: L10n.Localizable.Self.Settings.Advanced.DebuggingTools.EnterDebugCommand.title,
                isDestructive: false,
                selectAction: DebugActions.enterDebugCommand
            )
        ])

        // Inner group
        let debuggingToolsGroup = SettingsGroupCellDescriptor(
            items: [findUnreadConversationSection],
            title: L10n.Localizable.Self.Settings.Advanced.DebuggingTools.title
        )

        // Section
        return SettingsSectionDescriptor(cellDescriptors: [debuggingToolsGroup])
    }

    // MARK: - Helpers
    private var pushButtonAlertController: UIAlertController {
        let alert = UIAlertController(
            title: L10n.Localizable.Self.Settings.Advanced.ResetPushTokenAlert.title,
            message: L10n.Localizable.Self.Settings.Advanced.ResetPushTokenAlert.message,
            preferredStyle: .alert
        )

        let action = UIAlertAction(
            title: L10n.Localizable.General.ok,
            style: .default,
            handler: { [weak alert] _ in
                alert?.dismiss(animated: true, completion: nil)
            }
        )

        alert.addAction(action)

        return alert
    }

    private var presentVersionAction: (SettingsCellDescriptorType) -> Void {
        return { _ in
            let versionInfoViewController = VersionInfoViewController()
            var superViewController = UIApplication.shared.keyWindow?.rootViewController

            if let presentedViewController = superViewController?.presentedViewController {
                superViewController = presentedViewController
                versionInfoViewController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                versionInfoViewController.navigationController?.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            }

            superViewController?.present(versionInfoViewController, animated: true, completion: .none)
        }
    }
}
