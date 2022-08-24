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
import AppCenterDistribute

/// Flag to determine if the App Center SDK has already been initialized
private var didSetupAppCenter = false

/// Helper to setup crash reporting in the share extension
final class CrashReporter {

    static func setupAppCenterIfNeeded() {
        guard !didSetupAppCenter, appCenterEnabled, Bundle.appCenterAppId != nil else { return }
        didSetupAppCenter = true

        UserDefaults.standard.set(true, forKey: "kBITExcludeApplicationSupportFromBackup")

        // Enable after securing app extensions from App Center
        AppCenter.setTrackingEnabled(!ExtensionSettings.shared.disableCrashSharing)
        AppCenter.configure(withAppSecret: Bundle.appCenterAppId)
        AppCenter.start()

    }

    private static var appCenterEnabled: Bool {
        let configUseAppCenter = Bundle.useAppCenter // The preprocessor macro USE_APP_CENTER (from the .xcconfig files)
        let automationUseAppCenter = AutomationHelper.sharedHelper.useAppCenter // Command line argument used by automation
        let settingsDisableCrashAndAnalyticsSharing = ExtensionSettings.shared.disableCrashSharing // User consent

        return (automationUseAppCenter || (!automationUseAppCenter && configUseAppCenter))
            && !settingsDisableCrashAndAnalyticsSharing
    }
}
