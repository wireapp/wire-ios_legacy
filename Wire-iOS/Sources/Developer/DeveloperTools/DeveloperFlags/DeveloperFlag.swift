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

private let storage = UserDefaults(suiteName: "com.wire.developer-flags")!

enum DeveloperFlag: String, CaseIterable {

    case showCreateMLSGroupToggle
    case nseDebugging
    case useDevelopmentBackendAPI

    var description: String {
        switch self {
        case .showCreateMLSGroupToggle:
            return "Turn on to show the MLS toggle when creating a new group."

        case .nseDebugging:
            return "Turn on to make the notification service extension (NSE) display debug notifications."

        case .useDevelopmentBackendAPI:
            return "Turn on to use the developement backend API version instead of the latest production API version."
        }
    }

    var isOn: Bool {
        get { return storage.bool(forKey: rawValue) }
        set { storage.set(newValue, forKey: rawValue) }
    }

}
