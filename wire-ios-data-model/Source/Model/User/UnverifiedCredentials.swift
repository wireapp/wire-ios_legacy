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

import Foundation

/**
 * Credentials that needs to be verified; either a phone number or an e-mail address.
 */

public enum UnverifiedCredentials: Equatable {

    /// The e-mail that needs to be verified.
    case email(String)

    /// The phone number that needs to be verified.
    case phone(String)

    /// The label identifying the type of credential, that can be used in backend requests.
    public var type: String {
        switch self {
        case .email: return "email"
        case .phone: return "phone"
        }
    }

    /// The raw value representing the credentials provided by the user.
    public var rawValue: String {
        switch self {
        case .email(let email): return email
        case .phone(let phone): return phone
        }
    }
}
