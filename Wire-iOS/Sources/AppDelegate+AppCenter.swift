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
    
    @objc func setupAppCenter(with completion: @escaping () -> ()) {
        
        let shouldUseAppCenter = AutomationHelper.sharedHelper.useAppCenter || wr_useAppCenter()
        
        if !shouldUseAppCenter {
            completion()
            return
        }
        
        let userDefaults = UserDefaults.standard
        
        userDefaults.set(true, forKey: "kBITExcludeApplicationSupportFromBackup") //check
        let appCenterTrackingEnabled = !TrackingManager.shared.disableCrashAndAnalyticsSharing
        
        let appCenterId = "HOCKEY_APP-ID" // @STRINGIZE(HOCKEY_APP_ID_KEY)
        MSAppCenter.configure(withAppSecret: appCenterId)
        //[hockeyManager configureWithIdentifier:@STRINGIZE(HOCKEY_APP_ID_KEY) delegate:self];
        //[hockeyManager.authenticator setIdentificationType:BITAuthenticatorIdentificationTypeAnonymous];
        
        //BITHockeyManager *hockeyManager = [BITHockeyManager sharedHockeyManager];
        
        //if (! [BITHockeyManager sharedHockeyManager].crashManager.didCrashInLastSession) {
            UIApplication.shared.resetRunDuration()
        //}
        
        let cmdLineDisableUpdateManager = userDefaults.bool(forKey: "DisableHockeyUpdates")
        if cmdLineDisableUpdateManager {
            //hockeyManager.updateManager.updateSetting = BITUpdateCheckManually;
        }
        
        //hockeyManager.crashManager.crashManagerStatus = BITCrashManagerStatusAutoSend;
        
        MSAppCenter.setTrackingEnabled(appCenterTrackingEnabled) // We need to disable tracking before starting the manager!
        
        if appCenterTrackingEnabled {
            //[hockeyManager startManager];
            //[hockeyManager.authenticator authenticateInstallation];
        }
        
        //hockeyManager.crashManager.timeIntervalCrashInLastSessionOccurred < 5
        
        if appCenterTrackingEnabled &&
            MSCrashes.hasCrashedInLastSession() &&
            MSCrashes.timeIntervalCrashInLastSessionOccurred < 5 {
            zmLog.error("HockeyIntegration: START Waiting for the crash log upload...")
            self.appCenterInitCompletion = completion
            self.perform(#selector(crashReportUploadDone), with: nil, afterDelay: 5)
        } else {
            completion()
        }
    }
    
    @objc func crashReportUploadDone() {
        
        zmLog.error("HockeyIntegration: finished or timed out sending the crash report")
        
        if self.appCenterInitCompletion == nil {
            self.appCenterInitCompletion?()
            zmLog.error("HockeyIntegration: END Waiting for the crash log upload...")
            self.appCenterInitCompletion = nil
        }
        
    }
}

extension AppDelegate: MSCrashesDelegate {
    
    public func crashes(_ crashes: MSCrashes!, shouldProcessErrorReport errorReport: MSErrorReport!) -> Bool {
        return true // change to personal settings
    }
    
    public func crashes(_ crashes: MSCrashes!, willSend errorReport: MSErrorReport!) {
        UIApplication.shared.resetRunDuration()
    }
    
    public func crashes(_ crashes: MSCrashes!, didSucceedSending errorReport: MSErrorReport!) {
        crashReportUploadDone()
    }
}

/*

#pragma mark - BITHockeyManagerDelegate
- (NSString *)applicationLogForCrashManager:(BITCrashManager *)crashManager
{
    // get the content
    NSData *fileContent = [NSData dataWithContentsOfURL:ZMLastAssertionFile()];
    if(fileContent == nil) {
        return nil;
    }
    
    // delete it
    [[NSFileManager defaultManager] removeItemAtURL:ZMLastAssertionFile() error:nil];
    
    // return
    return [[NSString alloc] initWithData:fileContent encoding:NSUTF8StringEncoding];
}
*/
