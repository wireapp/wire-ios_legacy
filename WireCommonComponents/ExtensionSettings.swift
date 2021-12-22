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
import WireUtilities

private enum ExtensionSettingsKey: String, CaseIterable {

    case disableCrashSharing
    case disableAnalyticsSharing
    case disableLinkPreviews

    private var defaultValue: Any? {
        switch self {
        // Always disable analytics by default.
        case .disableCrashSharing:
            return true
        case .disableAnalyticsSharing:
            return false
        case .disableLinkPreviews:
            return false
        }
    }

    static var defaultValueDictionary: [String: Any] {
        return allCases.reduce([:]) { result, current in
            var mutableResult = result
            mutableResult[current.rawValue] = current.defaultValue
            return mutableResult
        }
    }

}

public class ExtensionSettings: NSObject {

    public static let shared = ExtensionSettings(defaults: .shared()!)

    private let defaults: UserDefaults

    public init(defaults: UserDefaults) {
        self.defaults = defaults
        super.init()
        setupDefaultValues()
    }

    private func setupDefaultValues() {
        defaults.register(defaults: ExtensionSettingsKey.defaultValueDictionary)
    }

    public func reset() {
        ExtensionSettingsKey.allCases.forEach {
            defaults.removeObject(forKey: $0.rawValue)
        }

        // As we purposely crash afterwards we manually call synchronize.
        defaults.synchronize()
    }

    public var disableAnalyticsSharing: Bool {
        get {
            return defaults.bool(forKey: ExtensionSettingsKey.disableAnalyticsSharing.rawValue)
        }
        set {
            defaults.set(newValue, forKey: ExtensionSettingsKey.disableAnalyticsSharing.rawValue)
        }
    }
    
    public var disableCrashSharing: Bool {
        get {
            return defaults.bool(forKey: ExtensionSettingsKey.disableCrashSharing.rawValue)
        }
        set {
            defaults.set(newValue, forKey: ExtensionSettingsKey.disableCrashSharing.rawValue)
        }
    }
    
    public var disableLinkPreviews: Bool {
        get {
            return defaults.bool(forKey: ExtensionSettingsKey.disableLinkPreviews.rawValue)
        }
        set {
            defaults.set(newValue, forKey: ExtensionSettingsKey.disableLinkPreviews.rawValue)
        }
    }
}
