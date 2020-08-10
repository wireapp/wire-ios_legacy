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

import WireCommonComponents
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
import AppCenterDistribute
import WireSystem
import UIKit

extension AppDelegate {

    var zmLog: ZMSLog {
        return ZMSLog(tag: "UI")
    }

    func setupAppCenter(completion: @escaping () -> Void) {

        let shouldUseAppCenter = AutomationHelper.sharedHelper.useAppCenter || Bundle.useAppCenter

        if !shouldUseAppCenter {
            completion()
            return
        }

        let userDefaults = UserDefaults.standard
        userDefaults.set(true, forKey: "kBITExcludeApplicationSupportFromBackup") //check

        let appCenterTrackingEnabled = !TrackingManager.shared.disableCrashAndAnalyticsSharing

        if appCenterTrackingEnabled {
            MSCrashes.setDelegate(self)
            MSDistribute.setDelegate(self)

            MSAppCenter.start()

            MSAppCenter.setLogLevel(.verbose)

            // This method must only be used after Services have been started.
            MSAppCenter.setTrackingEnabled(appCenterTrackingEnabled)
        }

        if appCenterTrackingEnabled &&
            MSCrashes.hasCrashedInLastSession() &&
            MSCrashes.timeIntervalCrashInLastSessionOccurred ?? 0 < TimeInterval(5) {
            zmLog.error("AppCenterIntegration: START Waiting for the crash log upload...")
            self.appCenterInitCompletion = completion
            self.perform(#selector(crashReportUploadDone), with: nil, afterDelay: 5)
        } else {
            completion()
        }
    }

    @objc
    private func crashReportUploadDone() {

        zmLog.error("AppCenterIntegration: finished or timed out sending the crash report")

        if appCenterInitCompletion != nil {
            appCenterInitCompletion?()
            zmLog.error("AppCenterIntegration: END Waiting for the crash log upload...")
            appCenterInitCompletion = nil
        }

    }
}

extension AppDelegate: MSDistributeDelegate {
    func distribute(_ distribute: MSDistribute!,
                    releaseAvailableWith details: MSReleaseDetails!) -> Bool {
        guard let window = window else { return false }

        let alertController = UIAlertController(title: "Update available \(details?.shortVersion ?? "") (\(details?.version ?? ""))",
            message: "Release Note:\n\n\(details?.releaseNotes ?? "")\n\nDo you want to update?",
            preferredStyle:.actionSheet)
        alertController.configPopover(pointToView: window)

        alertController.addAction(UIAlertAction(title: "Update", style: .cancel) {_ in
            MSDistribute.notify(.update)
        })

        alertController.addAction(UIAlertAction(title: "Postpone", style: .default) {_ in
            MSDistribute.notify(.postpone)
        })

        if let url = details.releaseNotesUrl {
            alertController.addAction(UIAlertAction(title: "View release note", style: .default) {_ in
                UIApplication.shared.open(url, options: [:])
            })
        }

        alertController.addAction(UIAlertAction(title: "Cancel", style: .default) {_ in })

        window.endEditing(true)
        window.rootViewController?.present(alertController, animated: true)

        return true
    }
}

extension AppDelegate: MSCrashesDelegate {

    public func crashes(_ crashes: MSCrashes!, shouldProcessErrorReport errorReport: MSErrorReport!) -> Bool {
        return !TrackingManager.shared.disableCrashAndAnalyticsSharing
    }

    public func crashes(_ crashes: MSCrashes!, didSucceedSending errorReport: MSErrorReport!) {
        crashReportUploadDone()
    }
}
