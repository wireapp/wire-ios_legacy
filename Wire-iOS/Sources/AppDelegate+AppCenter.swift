//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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


extension AppDelegate {
    
    var zmLog: ZMSLog {
        return ZMSLog(tag: "UI")
    }
    
    func setupAppCenter(completion: @escaping () -> ()) {
        
        let shouldUseAppCenter = AutomationHelper.sharedHelper.useAppCenter || Bundle.useAppCenter
        
        if !shouldUseAppCenter {
            completion()
            return
        }
        
        let userDefaults = UserDefaults.standard
        userDefaults.set(true, forKey: "kBITExcludeApplicationSupportFromBackup") //check
        
        let appCenterTrackingEnabled = !TrackingManager.shared.disableCrashAndAnalyticsSharing
        
        if !MSCrashes.hasCrashedInLastSession() {
            UIApplication.shared.resetRunDuration()
        }
        
        
        if appCenterTrackingEnabled {
            MSCrashes.setDelegate(self)
            
            MSAppCenter.start()
            
            MSAppCenter.setLogLevel(.verbose)
            
            // This method must only be used after Services have been started.
            MSAppCenter.setTrackingEnabled(appCenterTrackingEnabled)
        }
        
        if appCenterTrackingEnabled &&
            MSCrashes.hasCrashedInLastSession() &&
            MSCrashes.timeIntervalCrashInLastSessionOccurred < 5 {
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

extension AppDelegate: MSCrashesDelegate {
    
    public func crashes(_ crashes: MSCrashes!, shouldProcessErrorReport errorReport: MSErrorReport!) -> Bool {
        return !TrackingManager.shared.disableCrashAndAnalyticsSharing
    }
    
    public func crashes(_ crashes: MSCrashes!, willSend errorReport: MSErrorReport!) {
        UIApplication.shared.resetRunDuration()
    }
    
    public func crashes(_ crashes: MSCrashes!, didSucceedSending errorReport: MSErrorReport!) {
        crashReportUploadDone()
    }
    
}
