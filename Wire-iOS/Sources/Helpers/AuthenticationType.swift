//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

import LocalAuthentication


enum AuthenticationType: CaseIterable {

    case faceID, touchID, passcode, unavailable

    static var current: AuthenticationType {
        return AuthenticationTypeDetector().current
    }

}

struct AuthenticationTypeDetector: AuthenticationTypeProvider {

    var current: AuthenticationType {
        let context = LAContext()

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) else {
            return .unavailable
        }

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            return .passcode
        }

        guard #available(iOS 11.0, *) else {
            return .touchID
        }

        switch context.biometryType {
        case .none:
            return .passcode
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        @unknown default:
            return .passcode
        }
    }

}


protocol AuthenticationTypeProvider {

    var current: AuthenticationType { get }

}
