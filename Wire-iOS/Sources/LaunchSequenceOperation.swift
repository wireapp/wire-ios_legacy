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
import WireSyncEngine
import WireCommonComponents
import AppCenter
#if DISABLE_APPCENTER_CRASH_LOGGING
#else
import AppCenterCrashes
#endif
import AppCenterDistribute
import avs

// MARK: - LaunchSequenceOperation
protocol LaunchSequenceOperation {
    func execute()
}

// MARK: - BackendEnvironmentOperation
final class BackendEnvironmentOperation: LaunchSequenceOperation {
    func execute() {
        guard let backendTypeOverride = AutomationHelper.sharedHelper.backendEnvironmentTypeOverride() else {
            return
        }
        AutomationHelper.sharedHelper.persistBackendTypeOverrideIfNeeded(with: backendTypeOverride)
    }
}

// MARK: - PerformanceDebuggerOperation
final class PerformanceDebuggerOperation: LaunchSequenceOperation {
    func execute() {
        PerformanceDebugger.shared.start()
    }
}

// MARK: - ZMSLogOperation
final class ZMSLogOperation: LaunchSequenceOperation {
    func execute() {
        ZMSLog.switchCurrentLogToPrevious()
    }
}

// MARK: - ZMSLogOperation
final class AVSLoggingOperation: LaunchSequenceOperation {
    func execute() {
        SessionManager.startAVSLogging()
    }
}

// MARK: - AutomationHelperOperation
final class AutomationHelperOperation: LaunchSequenceOperation {
    func execute() {
        AutomationHelper.sharedHelper.installDebugDataIfNeeded()
    }
}

// MARK: - MediaManagerOperation
final class MediaManagerOperation: LaunchSequenceOperation {
    private let mediaManagerLoader = MediaManagerLoader()

    func execute() {
        mediaManagerLoader.send(message: .appStart)
    }
}

// MARK: - TrackingOperation
final class TrackingOperation: LaunchSequenceOperation {
    func execute() {
        let containsConsoleAnalytics = ProcessInfo.processInfo
            .arguments.contains(AnalyticsProviderFactory.ZMConsoleAnalyticsArgumentKey)

        AnalyticsProviderFactory.shared.useConsoleAnalytics = containsConsoleAnalytics
        Analytics.shared = Analytics(optedOut: TrackingManager.shared.disableAnalyticsSharing)
    }
}

// MARK: - FileBackupExcluderOperation
final class FileBackupExcluderOperation: LaunchSequenceOperation {
    private let fileBackupExcluder = FileBackupExcluder()

    func execute() {
        guard let appGroupIdentifier = Bundle.main.appGroupIdentifier else {
            return
        }

        let sharedContainerURL = FileManager.sharedContainerDirectory(for: appGroupIdentifier)
        fileBackupExcluder.excludeLibraryFolderInSharedContainer(sharedContainerURL: sharedContainerURL)
    }
}

// MARK: - AppCenterOperation
final class AppCenterOperation: NSObject, LaunchSequenceOperation {
    private var zmLog: ZMSLog {
        return ZMSLog(tag: "UI")
    }

    func execute() {
        guard AutomationHelper.sharedHelper.useAppCenter || Bundle.useAppCenter else {
            AppCenter.setTrackingEnabled(false)
            return
        }
        UserDefaults.standard.set(true, forKey: "kBITExcludeApplicationSupportFromBackup") // check

        guard !TrackingManager.shared.disableCrashSharing else {
            AppCenter.setTrackingEnabled(false)
            return
        }

#if DISABLE_APPCENTER_CRASH_LOGGING
#else
        Crashes.delegate = self
#endif
        Distribute.delegate = self

        AppCenter.start()

        AppCenter.logLevel = .verbose

        // This method must only be used after Services have been started.
        AppCenter.setTrackingEnabled(true)

    }
}

extension AppCenterOperation: DistributeDelegate {
    func distribute(_ distribute: Distribute, releaseAvailableWith details: ReleaseDetails) -> Bool {

        guard
            let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let window = appDelegate.window,
            let rootViewController = appDelegate.appRootRouter?.rootViewController
        else {
            return false
        }

        let alertController = UIAlertController(title: "Update available \(details.shortVersion ?? "") (\(details.version ?? ""))",
                                                message: "Release Note:\n\n\(details.releaseNotes ?? "")\n\nDo you want to update?",
            preferredStyle: .actionSheet)
        alertController.configPopover(pointToView: window)

        alertController.addAction(UIAlertAction(title: "Update", style: .cancel) {_ in
            Distribute.notify(.update)
        })

        alertController.addAction(UIAlertAction(title: "Postpone", style: .default) {_ in
            Distribute.notify(.postpone)
        })

        if let url = details.releaseNotesUrl {
            alertController.addAction(UIAlertAction(title: "View release note", style: .default) {_ in
                UIApplication.shared.open(url, options: [:])
            })
        }

        alertController.addAction(UIAlertAction(title: "Cancel", style: .default) {_ in })

        window.endEditing(true)
        rootViewController.present(alertController, animated: true)

        return true
    }
}

#if DISABLE_APPCENTER_CRASH_LOGGING
#else
extension AppCenterOperation: CrashesDelegate {

    func crashes(_ crashes: Crashes, shouldProcess errorReport: ErrorReport) -> Bool {
        return !TrackingManager.shared.disableCrashSharing
    }

    internal func crashes(_ crashes: Crashes, didSucceedSending errorReport: ErrorReport) {
        zmLog.error("AppCenter: finished sending the crash report")
    }

    internal func crashes(_ crashes: Crashes, didFailSending errorReport: ErrorReport, withError error: Error?) {
        zmLog.error("AppCenter: failed sending the crash report with error: \(String(describing: error?.localizedDescription))")
    }
}
#endif

// MARK: - APIVersionOperation

final class APIVersionOperation: LaunchSequenceOperation {

    func execute() {
        APIVersion.storage = .applicationGroup
    }

}
