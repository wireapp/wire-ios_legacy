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

/**
 * An object that provides the available features in the authentication flow.
 */

protocol AuthenticationFeatureProvider {
    /// Whether the user can log in or sign up with phone number.
    var phoneNumberSupported: Bool { get }

    /// Whether new accounts can be created.
    var registrationSupported: Bool { get }
}

/**
 * Reads the authentication features from the build settings.
 */

class BuildSettingAuthenticationFeatureProvider: AuthenticationFeatureProvider {

    var phoneNumberSupported: Bool {
        #if !PHONE_AUTHENTICATION_DISABLED
        return true
        #else
        return false
        #endif
    }

    var registrationSupported: Bool {
        #if !ACCOUNT_CREATION_DISABLED
        return true
        #else
        return false
        #endif
    }

}

