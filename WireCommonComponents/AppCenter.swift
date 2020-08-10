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

import Foundation
import AppCenter
import AppCenterCrashes
import AppCenterDistribute
import AppCenterAnalytics

public extension MSAppCenter {
    
    static func setTrackingEnabled(_ enabled: Bool) {
        MSAnalytics.setEnabled(enabled)
        MSDistribute.setEnabled(enabled)
        MSCrashes.setEnabled(enabled)
    }
    
    static func start() {
        MSDistribute.updateTrack = .private

        MSAppCenter.start(Bundle.appCenterAppId, withServices: [MSCrashes.self,
                                                                MSDistribute.self,
                                                                MSAnalytics.self])
    }
}

public extension MSCrashes {
    
    static var timeIntervalCrashInLastSessionOccurred: TimeInterval? {
        guard let lastSessionCrashReport = lastSessionCrashReport() else { return nil }
        return lastSessionCrashReport.appErrorTime.timeIntervalSince(lastSessionCrashReport.appStartTime)
    }
}

public extension Bundle {
    
    static var appCenterAppId: String? {
        guard let scheme = Bundle.appMainBundle.infoDictionary?["CFBundleURLTypes"] as? [[String:Any]],
            let item = scheme.first,
            let key = item["CFBundleURLSchemes"] as? [String],
            let appCenterID = key.first else { return nil }
        return appCenterID.replacingOccurrences(of: "appcenter-", with: "")
    }
    
    static var useAppCenter: Bool {
        return Bundle.appMainBundle.infoForKey("UseAppCenter") == "1"
    }
}
