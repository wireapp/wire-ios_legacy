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
            title: "self.settings.advanced.title".localized,
            icon: .settingsAdvanced
        )
    }

    // MARK: - Sections
    private var troubleshootingSection: SettingsSectionDescriptor {
        let submitDebugButton = SettingsExternalScreenCellDescriptor(
            title: "self.settings.advanced.troubleshooting.submit_debug.title".localized,
            presentationAction: { () -> (UIViewController?) in
                return SettingsTechnicalReportViewController()
        })

        return SettingsSectionDescriptor(
            cellDescriptors: [submitDebugButton],
            header: "self.settings.advanced.troubleshooting.title".localized,
            footer: "self.settings.advanced.troubleshooting.submit_debug.subtitle".localized
        )
    }

    private var pushSection: SettingsSectionDescriptor {
        let pushButton = SettingsExternalScreenCellDescriptor(
            title: "self.settings.advanced.reset_push_token.title".localized,
            isDestructive: false,
            presentationStyle: PresentationStyle.modal,
            presentationAction: { () -> (UIViewController?) in
                ZMUserSession.shared()?.validatePushToken()
                return self.pushButtonAlertController
        })

        return SettingsSectionDescriptor(
            cellDescriptors: [pushButton],
            header: .none,
            footer: "self.settings.advanced.reset_push_token.subtitle".localized,
            visibilityAction: { _ in
                return true
        })
    }

    private var versionSection: SettingsSectionDescriptor {
        let versionCell = SettingsButtonCellDescriptor(
            title: "self.settings.advanced.version_technical_details.title".localized,
            isDestructive: false,
            selectAction: presentVersionAction
        )

        return SettingsSectionDescriptor(cellDescriptors: [versionCell])
    }

    private var debuggingToolsSection: SettingsSectionDescriptor {

        let findUnreadConversationSection = SettingsSectionDescriptor(cellDescriptors: [
            SettingsButtonCellDescriptor(
                title: "self.settings.advanced.debugging_tools.first_unread_conversation.title".localized,
                isDestructive: false,
                selectAction: DebugActions.findUnreadConversationContributingToBadgeCount
            ),
            SettingsButtonCellDescriptor(
                title: "self.settings.advanced.debugging_tools.show_user_id.title".localized,
                isDestructive: false,
                selectAction: DebugActions.showUserId
            ),
            SettingsButtonCellDescriptor(
                title: "self.settings.advanced.debugging_tools.enter_debug_command.title".localized,
                isDestructive: false,
                selectAction: DebugActions.enterDebugCommand
            )
        ])

        // Inner group
        let debuggingToolsGroup = SettingsGroupCellDescriptor(
            items: [findUnreadConversationSection],
            title: "self.settings.advanced.debugging_tools.title".localized
        )

        // Section
        return SettingsSectionDescriptor(cellDescriptors: [debuggingToolsGroup])
    }

    // MARK: - Helpers
    private var pushButtonAlertController: UIAlertController {
        let alert = UIAlertController(
            title: "self.settings.advanced.reset_push_token_alert.title".localized,
            message: "self.settings.advanced.reset_push_token_alert.message".localized,
            preferredStyle: .alert
        )

        let action = UIAlertAction(
            title: "general.ok".localized,
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
            var superViewController = UIApplication.shared.firstKeyWindow?.rootViewController

            if let presentedViewController = superViewController?.presentedViewController {
                superViewController = presentedViewController
                versionInfoViewController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                versionInfoViewController.navigationController?.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            }

            superViewController?.present(versionInfoViewController, animated: true, completion: .none)
        }
    }
}
