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

/**
 * The result of password validation.
 */

public enum PasswordValidationResult: Equatable {

    /// The password is valid.
    case valid

    /// The password is invalid due to the violations.
    case invalid(violations: [Violation])

    public enum Violation: Equatable {

        /// The password is too short.
        case tooShort

        /// The password is too long.
        case tooLong

        /// The password contains a disallowed character.
        case disallowedCharacter(Unicode.Scalar)

        /// The password does not satisfy a requirement for a character class.
        case missingRequiredClasses(Set<PasswordCharacterClass>)
    }

}
