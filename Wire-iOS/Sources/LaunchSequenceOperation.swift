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
import AppCenterCrashes
import AppCenterDistribute
import avs

// MARK: - LaunchSequenceOperation
public protocol LaunchSequenceOperation {
    func execute()
}

// MARK: - BackendEnvironmentOperation
final class BackendEnvironmentOperation: LaunchSequenceOperation {
    public func execute() {
        guard let backendTypeOverride = AutomationHelper.sharedHelper.backendEnvironmentTypeOverride() else {
            return
        }
        AutomationHelper.sharedHelper.persistBackendTypeOverrideIfNeeded(with: backendTypeOverride)
    }
}

// MARK: - PerformanceDebuggerOperation
final class PerformanceDebuggerOperation: LaunchSequenceOperation {
    public func execute() {
        PerformanceDebugger.shared.start()
    }
}

// MARK: - ZMSLogOperation
final class ZMSLogOperation: LaunchSequenceOperation {
    public func execute() {
        ZMSLog.switchCurrentLogToPrevious()
    }
}

// MARK: - ZMSLogOperation
final class AVSLoggingOperation: LaunchSequenceOperation {
    public func execute() {
        SessionManager.startAVSLogging()
    }
}

// MARK: - AutomationHelperOperation
final class AutomationHelperOperation: LaunchSequenceOperation {
    public func execute() {
        AutomationHelper.sharedHelper.installDebugDataIfNeeded()
    }
}

// MARK: - MediaManagerOperation
final class MediaManagerOperation: LaunchSequenceOperation {
    private let mediaManagerLoader = MediaManagerLoader()
    
    public func execute() {
        mediaManagerLoader.send(message: .appStart)
    }
}

// MARK: - TrackingOperation
final class TrackingOperation: LaunchSequenceOperation {
    public func execute() {
        let containsConsoleAnalytics = ProcessInfo.processInfo
            .arguments.contains(AnalyticsProviderFactory.ZMConsoleAnalyticsArgumentKey)
        
        AnalyticsProviderFactory.shared.useConsoleAnalytics = containsConsoleAnalytics
        Analytics.shared = Analytics(optedOut: TrackingManager.shared.disableAnalyticsSharing)
    }
}

// MARK: - FileBackupExcluderOperation
final class FileBackupExcluderOperation: LaunchSequenceOperation {
    private let fileBackupExcluder = FileBackupExcluder()
    
    public func execute() {
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
    
    public func execute() {
        guard AutomationHelper.sharedHelper.useAppCenter || Bundle.useAppCenter else {
            MSAppCenter.setTrackingEnabled(false)
            return
        }
        UserDefaults.standard.set(true, forKey: "kBITExcludeApplicationSupportFromBackup") //check
        
        guard !TrackingManager.shared.disableCrashSharing else {
            MSAppCenter.setTrackingEnabled(false)
            return
        }
        
        MSCrashes.setDelegate(self)
        MSDistribute.setDelegate(self)
        
        MSAppCenter.start()
        
        MSAppCenter.setLogLevel(.verbose)
        
        // This method must only be used after Services have been started.
        MSAppCenter.setTrackingEnabled(true)
        
    }
}

extension AppCenterOperation: MSDistributeDelegate {
    func distribute(_ distribute: MSDistribute!,
                    releaseAvailableWith details: MSReleaseDetails!) -> Bool {
        
        guard
            let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let window = appDelegate.window,
            let rootViewController = appDelegate.appRootRouter?.rootViewController
        else {
            return false
        }

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
        rootViewController.present(alertController, animated: true)

        return true
    }
}

extension AppCenterOperation: MSCrashesDelegate {

    public func crashes(_ crashes: MSCrashes!, shouldProcessErrorReport errorReport: MSErrorReport!) -> Bool {
        return !TrackingManager.shared.disableCrashSharing
    }

    public func crashes(_ crashes: MSCrashes!, didSucceedSending errorReport: MSErrorReport!) {
        zmLog.error("AppCenter: finished sending the crash report")
    }
    
    public func crashes(_ crashes: MSCrashes!, didFailSending errorReport: MSErrorReport!, withError error: Error!) {
        zmLog.error("AppCenter: failed sending the crash report with error: \(error.localizedDescription)")
    }
}
