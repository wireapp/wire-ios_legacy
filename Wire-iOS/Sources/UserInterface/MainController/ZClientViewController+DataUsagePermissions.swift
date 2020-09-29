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
import UIKit
import WireCommonComponents

extension ZClientViewController {
    
    func createDataUsagePermissionDialogIfNeeded() -> UIAlertController? {
        guard !AutomationHelper.sharedHelper.skipFirstLoginAlerts else { return nil }
        
        guard !dataCollectionDisabled else { return nil }
        
        // If the usage dialog was already displayed in this run, do not show it again
        guard !dataUsagePermissionDialogDisplayed else { return nil }
        
        // Check if the app state requires showing the alert
        guard needToShowDataUsagePermissionDialog else { return nil }
        
        // If the user registers, show the alert.
        guard isComingFromRegistration else { return nil }
        
        let alertController = UIAlertController(title: "conversation_list.data_usage_permission_alert.title".localized, message: "conversation_list.data_usage_permission_alert.message".localized, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "conversation_list.data_usage_permission_alert.disagree".localized, style: .cancel, handler: { (_) in
            TrackingManager.shared.disableCrashSharing = true
            TrackingManager.shared.disableAnalyticsSharing = true
        }))
        
        alertController.addAction(UIAlertAction(title: "conversation_list.data_usage_permission_alert.agree".localized, style: .default, handler: { (_) in
            TrackingManager.shared.disableCrashSharing = false
            TrackingManager.shared.disableAnalyticsSharing = false
        }))
        
        return alertController
    }
    
    func showDataUsagePermissionDialogIfNeeded() {
        
        guard let alertController = createDataUsagePermissionDialogIfNeeded() else { return }

        present(alertController, animated: true)

        dataUsagePermissionDialogDisplayed = true
    }
    
    private var dataCollectionDisabled: Bool {
        #if DATA_COLLECTION_DISABLED
        return true
        #else
        return false
        #endif
    }

}
