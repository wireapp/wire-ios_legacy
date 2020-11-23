//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

extension AppLock {

    /// Describes the authentication method available on the device.

    enum AuthenticationMethod: Equatable {

        /// FaceID is supported. If `enrolled` then it is available, otherwise
        /// the user needs to enabled it.

        case faceID(enrolled: Bool)

        /// TouchID is supported. If `enrolled` then it is available, otherwise
        /// the user needs to enabled it.

        case touchID(enrolled: Bool)

        /// The device passcode is set.

        case devicePasscode

        /// No authentication method available.

        case none
    }

    /// Returns the authentication methd available on the device.

    static func discoverAuthenticationMethod(in context: LAContextProtocol) -> AuthenticationMethod {
        var error: NSError?

        let isBiometryAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        if #available(iOS 11, *) {
            switch context.biometryType {
            case .faceID where isBiometryAvailable:
                return .faceID(enrolled: true)

            case .faceID where error.isBiometryNotEnrolled:
                return .faceID(enrolled: false)

            case .touchID where isBiometryAvailable:
                return .touchID(enrolled: true)

            case .touchID where error.isBiometryNotEnrolled:
                return .touchID(enrolled: false)

            default:
                break
            }
        } else {
            if isBiometryAvailable {
                return .touchID(enrolled: true)
            } else if error.isBiometryNotEnrolled {
                return .touchID(enrolled: false)
            }
        }

        let isPasscodeAvailable = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)

        if isPasscodeAvailable {
            return .devicePasscode
        }

        return .none
    }

}

protocol LAContextProtocol {

    @available(iOS 11, *)
    var biometryType: LABiometryType { get }

    func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool

}

private extension Optional where Wrapped == NSError {

    var isBiometryNotEnrolled: Bool {
        guard let code = self?.code else { return false }

        if #available(iOS 11, *) {
            return code == LAError.biometryNotEnrolled.rawValue
        } else {
            return code == LAError.touchIDNotEnrolled.rawValue
        }
    }

}
