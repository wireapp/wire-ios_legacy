//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

public extension AppLockController {

    struct Config {

        public let isAvailable: Bool
        public let isForced: Bool
        public let timeout: UInt

        public init(isAvailable: Bool, isForced: Bool, timeout: UInt) {
            self.isAvailable = isAvailable
            self.isForced = isForced
            self.timeout = timeout
        }

    }

    /// The legacy config is determined at compile time through the SessionManagerConfiguration, which
    /// is only used by whitelabel custom builds. The new config is retrieved from the backend using
    /// the 'features' endpoint.

    struct LegacyConfig: Codable {

        public let isForced: Bool
        public let timeout: UInt
        public let requireCustomPasscode: Bool

        public init(isForced: Bool = false, timeout: UInt = 10, requireCustomPasscode: Bool = false) {
            self.isForced = isForced
            self.timeout = timeout
            self.requireCustomPasscode = requireCustomPasscode
        }

    }

}
