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


import WireExtensionComponents
import HockeySDK.BITHockeyManager


/// Flag to determine if the HockeySDK has alreday been initialized (https://github.com/bitstadium/HockeySDK-iOS#34-ios-extensions)
private var didSetupHockey = false


/// Helper to setup crash reporting in the share extension
class CrashReporter {

    static func setupHockeyIfNeeded() {
        guard !didSetupHockey, hockeyEnabled, let hockeyIdentifier = wr_hockeyAppId() else { return }
        didSetupHockey = true

        // See https://github.com/bitstadium/HockeySDK-iOS/releases/tag/4.0.1
        UserDefaults.standard.set(true, forKey: "kBITExcludeApplicationSupportFromBackup")

        let manager = BITHockeyManager.shared()
        manager.setTrackingEnabled(!ExtensionSettings.shared.disableCrashAndAnalyticsSharing)
        manager.configure(withIdentifier: hockeyIdentifier)
        manager.crashManager.crashManagerStatus = .autoSend
        manager.start()
    }

    private static var hockeyEnabled: Bool {
        let configUseHockey = wr_useHockey() // The preprocessor macro USE_HOCKEY (from the .xcconfig files)
        let automationUseHockey = AutomationHelper.sharedHelper.useHockey // Command line argument used by automation
        let settingsDisableCrashAndAnalyticsSharing = ExtensionSettings.shared.disableCrashAndAnalyticsSharing // User consent

        return (automationUseHockey || (!automationUseHockey && configUseHockey))
            && !settingsDisableCrashAndAnalyticsSharing
    }
    
}

