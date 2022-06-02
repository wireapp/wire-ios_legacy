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
import LocalAuthentication

/// A type representing rules regarding which passcode types
/// are permitted to be used to authenticate the app lock.

public enum AppLockPasscodePreference {

    /// The device passcode is preferred, if available,
    /// otherwise use the custom passcode.

    case deviceThenCustom

    /// Only the device passcode is permitted.

    case deviceOnly

    /// Only the custom passcode is permitted.

    case customOnly

    // MARK: - Methods

    var policy: LAPolicy {
        switch self {
        case .deviceThenCustom, .deviceOnly:
            return .deviceOwnerAuthentication
        case .customOnly:
            return .deviceOwnerAuthenticationWithBiometrics
        }
    }

    var allowsCustomPasscode: Bool {
        switch self {
        case .customOnly, .deviceThenCustom:
            return true
        case .deviceOnly:
            return false
        }
    }

    var allowsDevicePasscode: Bool {
        switch self {
        case .deviceOnly, .deviceThenCustom:
            return true
        case .customOnly:
            return false
        }
    }

}
