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
    
    func advancedGroup() -> SettingsCellDescriptorType {
        var items = [SettingsSectionDescriptor]()
        
        items.append(contentsOf: [
            conferenceCallingSection,
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
    
    private var conferenceCallingSection: SettingsSectionDescriptor {
        let sectionTitle = "self.settings.advanced.conference_calling.title".localized
        let sectionSubtitle = "self.settings.advanced.conference_calling.subtitle".localized
        let betaToggle = SettingsPropertyToggleCellDescriptor(settingsProperty: settingsPropertyFactory.property(.enableConferenceCallingBeta))
        
        return SettingsSectionDescriptor(cellDescriptors: [betaToggle], header: sectionTitle, footer: sectionSubtitle)
    }
    
    private var troubleshootingSection: SettingsSectionDescriptor {
        let sectionTitle = "self.settings.advanced.troubleshooting.title".localized
        let buttonTitle = "self.settings.advanced.troubleshooting.submit_debug.title".localized
        let sectionSubtitle = "self.settings.advanced.troubleshooting.submit_debug.subtitle".localized
        let submitDebugButton = SettingsExternalScreenCellDescriptor(title: buttonTitle) { () -> (UIViewController?) in
            return SettingsTechnicalReportViewController()
        }
        
        return SettingsSectionDescriptor(cellDescriptors: [submitDebugButton], header: sectionTitle, footer: sectionSubtitle)
    }
    
    private var pushSection: SettingsSectionDescriptor {
        let buttonTitle = "self.settings.advanced.reset_push_token.title".localized
        let sectionSubtitle = "self.settings.advanced.reset_push_token.subtitle".localized
        
        let pushButton = SettingsExternalScreenCellDescriptor(title: buttonTitle, isDestructive: false, presentationStyle: PresentationStyle.modal, presentationAction: { () -> (UIViewController?) in
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
        
        return SettingsSectionDescriptor(cellDescriptors: [pushButton], header: .none, footer: sectionSubtitle) { (_) -> (Bool) in
            return true
        }
    }
    
    private var versionSection: SettingsSectionDescriptor {
        let title =  "self.settings.advanced.version_technical_details.title".localized
        let versionCell = SettingsButtonCellDescriptor(title: title, isDestructive: false) { _ in
            let versionInfoViewController = VersionInfoViewController()
            var superViewController = UIApplication.shared.keyWindow?.rootViewController
            if let presentedViewController = superViewController?.presentedViewController {
                superViewController = presentedViewController
                versionInfoViewController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                versionInfoViewController.navigationController?.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            }
            superViewController?.present(versionInfoViewController, animated: true, completion: .none)
        }
        
        return SettingsSectionDescriptor(cellDescriptors: [versionCell])
    }
    
    private var debuggingToolsSection: SettingsSectionDescriptor {
        let title = "self.settings.advanced.debugging_tools.title".localized
        
        let findUnreadConversationButton = SettingsButtonCellDescriptor(
            title: "self.settings.advanced.debugging_tools.first_unread_conversation.title".localized,
            isDestructive: false,
            selectAction: SettingsCellDescriptorFactory.findUnreadConversationContributingToBadgeCount
        )

        let debuggingToolsGroup = SettingsGroupCellDescriptor(items: [SettingsSectionDescriptor(cellDescriptors:[findUnreadConversationButton])], title: title)
       
        return SettingsSectionDescriptor(cellDescriptors: [debuggingToolsGroup],
                                         header: .none,
                                         footer: .none
        )
    }
}
