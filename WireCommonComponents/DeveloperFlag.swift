//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

public enum DeveloperFlag: String, CaseIterable {

    private static let storage = UserDefaults.applicationGroup

    case showCreateMLSGroupToggle
    case breakMyNotifications
    case nseV2
    case nseDebugging
    case nseDebugEntryPoint
    case useDevelopmentBackendAPI
    case deprecatedCallingUI

    public var description: String {
        switch self {
        case .showCreateMLSGroupToggle:
            return "Turn on to show the MLS toggle when creating a new group."

        case .breakMyNotifications:
            return "Turn on to get your app in a state where it no longer receives notifications."

        case .nseV2:
            return "Turn on to use the new implementation of the notification service extension."

        case .nseDebugging:
            return "Turn on to make the notification service extension (NSE) display debug notifications."

        case .nseDebugEntryPoint:
            return "Turn on to display a notification immediately at the entry point of the notification service extension, skipping any further push processing."

        case .useDevelopmentBackendAPI:
            return "Turn on to use the developement backend API version instead of the latest production API version."

        case .deprecatedCallingUI:
            return "Turn on to use deprecated calling UI"

        }
    }

    public var isOn: Bool {
        get { return Self.storage.bool(forKey: rawValue) }
        set { Self.storage.set(newValue, forKey: rawValue) }
    }

    static public func clearAllFlags() {
        allCases.forEach {
            storage.set(nil, forKey: $0.rawValue)
        }
    }

}

public extension DeveloperFlag {

    static var isUpdatedCallingUI: Bool {
        return !(DeveloperFlag.deprecatedCallingUI.isOn || AutomationHelper.sharedHelper.deprecatedCallingUI)
    }

}
