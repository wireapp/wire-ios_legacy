//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

extension ConversationListViewController {
    @objc func showDataUsagePermissionDialogIfNeeded() {
        guard !AutomationHelper.sharedHelper.skipFirstLoginAlerts else { return }

        // If the usage dialog was already displayed in this run, do not show it again
        guard !dataUsagePermissionDialogDisplayed else { return }

        // Check if the app state requires showing the alert
        guard needToShowDataUsagePermissionDialog else { return }

        // If the user registers, show the alert.
        // If the user logs in and hasn't accepted analytics yet, show the alert.
        guard isComingFromRegistration ||
              (isComingFromSetUsername && ZMUser.selfUser().isTeamMember) ||
              !userAcceptedAnalytics else { return }

        let alertController = UIAlertController(title: "conversation_list.data_usage_permission_alert.title".localized, message: "conversation_list.data_usage_permission_alert.message".localized, preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: "conversation_list.data_usage_permission_alert.disagree".localized, style: .cancel, handler: { (_) in
            TrackingManager.shared.disableCrashAndAnalyticsSharing = true
        }))
        
        alertController.addAction(UIAlertAction(title: "conversation_list.data_usage_permission_alert.agree".localized, style: .default, handler: { (_) in
            TrackingManager.shared.disableCrashAndAnalyticsSharing = false
        }))

        ZClientViewController.shared()?.present(alertController, animated: true) { [weak self] in
            self?.dataUsagePermissionDialogDisplayed = true
        }
    }

    private var userAcceptedAnalytics: Bool {
        return TrackingManager.shared.disableCrashAndAnalyticsSharing == false
    }
}
