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
        guard !dataUsagePermissionDialogDisplayed else { return }
        guard needToShowDataUsagePermissionDialog else { return }

        guard isComingFromRegistration ||
              (isComingFromSetUsername && ZMUser.selfUser().isTeamMember) ||
              TrackingManager.shared.disableCrashAndAnalyticsSharing else { return }

        let alertController = UIAlertController(title: "conversation_list.date_usage_permission_alert.title".localized, message: "conversation_list.date_usage_permission_alert.message".localized, preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: "general.accept".localized, style: .default, handler: { (_) in
            TrackingManager.shared.disableCrashAndAnalyticsSharing = false
        }))

        alertController.addAction(UIAlertAction(title: "general.skip".localized, style: .cancel, handler: { (_) in
            TrackingManager.shared.disableCrashAndAnalyticsSharing = true
        }))


        ZClientViewController.shared()?.present(alertController, animated: true) { [weak self] in
            self?.dataUsagePermissionDialogDisplayed = true
        }
    }
}
