//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

private let zmLog = ZMSLog(tag: "Analytics")

fileprivate let ZMEnableConsoleLog = "ZMEnableAnalyticsLog"

@objcMembers class AnalyticsProviderFactory: NSObject {
    @objc public static let shared = AnalyticsProviderFactory(userDefaults: .shared()!)
    @objc public static let ZMConsoleAnalyticsArgumentKey = "-ConsoleAnalytics"

    @objc public var useConsoleAnalytics: Bool = false

    private let userDefaults: UserDefaults

    @objc public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
  
    public func analyticsProvider() -> AnalyticsProvider? {
        if self.useConsoleAnalytics || UserDefaults.standard.bool(forKey: ZMEnableConsoleLog) {
            zmLog.info("Creating analyticsProvider: AnalyticsConsoleProvider")
            return AnalyticsConsoleProvider()
        }
        else if UseAnalytics.boolValue || AutomationHelper.sharedHelper.useAnalytics {
            // Create & return valid provider, when available.
            return nil
        }
        else {
            zmLog.info("Creating analyticsProvider: no provider")
            return nil
        }
    }
}

