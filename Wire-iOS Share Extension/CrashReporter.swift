//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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


/// Flag to determine if the App Center SDK has alreday been initialized (https://github.com/bitstadium/HockeySDK-iOS#34-ios-extensions)
private var didSetupAppCenter = false


/// Helper to setup crash reporting in the share extension
class CrashReporter {

    static func setupAppCenterIfNeeded() {
        guard !didSetupAppCenter, appCenterEnabled, let appCenterIdentifier = wr_appCenterAppId() else { return }
        didSetupAppCenter = true

        // See https://github.com/bitstadium/HockeySDK-iOS/releases/tag/4.0.1
        UserDefaults.standard.set(true, forKey: "kBITExcludeApplicationSupportFromBackup")

        MSAppCenter.start(appCenterIdentifier, withServices: [MSCrashes.self, MSDistribute.self])
        /*
        let manager = BITHockeyManager.shared()
        manager.setTrackingEnabled(!ExtensionSettings.shared.disableCrashAndAnalyticsSharing)
        manager.configure(withIdentifier: appCenterIdentifier)
        manager.crashManager.crashManagerStatus = .autoSend
        manager.start()*/
    }

    private static var appCenterEnabled: Bool {
        let configUseAppCenter = wr_useAppCenter() // The preprocessor macro USE_APP_CENTER (from the .xcconfig files)
        let automationUseAppCenter = AutomationHelper.sharedHelper.useAppCenter // Command line argument used by automation
        let settingsDisableCrashAndAnalyticsSharing = ExtensionSettings.shared.disableCrashAndAnalyticsSharing // User consent

        return (automationUseAppCenter || (!automationUseAppCenter && configUseAppCenter))
            && !settingsDisableCrashAndAnalyticsSharing
    }
    
}

