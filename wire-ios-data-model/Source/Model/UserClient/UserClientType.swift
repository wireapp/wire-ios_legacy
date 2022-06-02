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

@objc public protocol UserClientType: NSObjectProtocol {

    /// Free-form string decribing the client, this information is only available for your own clients.
    var label: String? { get }
    /// Remote identifier of the client
    var remoteIdentifier: String? { get }
    /// Owner of the client
    var user: ZMUser? { get }
    /// Date of when the client was activated, this information is only available for your own clients
    var activationDate: Date? { get }
    /// Type of client
    var type: DeviceType { get }
    /// Model of the device, this information is only available for your own clients
    var model: String? { get }
    /// The device class (phone, desktop, ...)
    var deviceClass: DeviceClass? { get }
    /// Estimated address of where the device was activated, , this information is only available for your own clients
    var activationAddress: String? { get }
    /// Estimated latitude of where the device was activated, this information is only available for your own clients
    var activationLatitude: Double { get }
    /// Estimated longitude of where the device was activated, this information is only available for your own clients
    var activationLongitude: Double { get }
    /// Unique fingerprint which can be used to identify & verify the client
    var fingerprint: Data? { get }
    /// True if the self user has verfied the client
    var verified: Bool { get }

    /// Delete any existing session with client and establish a new one.
    func resetSession()

    /// Returns true if this is the active client of the self user
    func isSelfClient() -> Bool

    /// Fetches the fingerprint or the prekeys of the device.
    func fetchFingerprintOrPrekeys()
}
