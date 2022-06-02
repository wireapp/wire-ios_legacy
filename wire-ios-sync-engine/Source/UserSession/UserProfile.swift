//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

@objc public protocol UserProfile: NSObjectProtocol {

    /// Requests phone number verification. Once this is called,
    /// the user is expected to receive a PIN code on her phone
    /// and call `requestPhoneNumberChange` with that PIN
    func requestPhoneVerificationCode(phoneNumber: String)

    /// Requests phone number change, with a PIN received earlier
    func requestPhoneNumberChange(credentials: ZMPhoneCredentials)

    /// Requests phone number removal. Must still have an email set.
    func requestPhoneNumberRemoval()

    /// Requests email change
    /// The email will need to be verified externally
    /// - throws: if the email is not already set, or if empty email is passed
    func requestEmailChange(email: String) throws

    /// Requests to set an email and password, for a user that does not have either.
    /// Once this is called, we expect the user to eventually verify the email externally.
    /// - throws: if the email was already set, or if empty credentials are passed
    func requestSettingEmailAndPassword(credentials: ZMEmailCredentials) throws

    /// Cancel setting email and password
    func cancelSettingEmailAndPassword()

    /// Requests a check of availability for a handle
    func requestCheckHandleAvailability(handle: String)

    /// Requests setting the handle
    func requestSettingHandle(handle: String)

    /// Cancels setting the handle
    func cancelSettingHandle()

    /// Generates somes possible user handles,
    /// and invokes a callback when it finds one that is available
    func suggestHandles()

    /// Add an observer for callbacks about the user profile.
    /// Returns a token which should retained as long as the observer should be active.
    @objc(addObserver:) func add(observer: UserProfileUpdateObserver) -> Any

    /// Last handle to have been suggested
    @objc var lastSuggestedHandle: String? { get }

}
