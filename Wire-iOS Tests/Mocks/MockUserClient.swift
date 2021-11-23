//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import WireSyncEngine

final class MockUserClient: NSObject, UserClientType {

    var type: DeviceType = .permanent

    var label: String?

    var remoteIdentifier: String?

    var activationAddress: String?

    var activationDate: Date?

    var model: String?

    var activationLatitude: Double = 0

    var activationLongitude: Double = 0

    var fingerprint: Data?

    var verified: Bool = false

    var user: ZMUser?

    var deviceClass: DeviceClass? = .phone

    func isSelfClient() -> Bool {
        return false
    }

    func resetSession() {
        // No-op
    }

    func fetchFingerprintOrPrekeys() {
        // No-op
    }

}
