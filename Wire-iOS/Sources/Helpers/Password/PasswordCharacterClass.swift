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

/**
 * The characters that can be used in a password safety rule.
 */

public enum PasswordCharacterClass: Hashable, Decodable {

    /// All unicode characters.
    case unicode

    /// All uppercase characters.
    case uppercase

    /// All lowercase characters.
    case lowercase

    /// All the digits between 0 and 9.
    case digits

    /// Special characters.
    case special

    /// All ASCII printable characters.
    case asciiPrintable

    /// A user-defined character set.
    case custom(String)

    // MARK: - Raw Representation

    /**
     * Creates the character class from its raw representation.
     * - parameter rawValue: The string describing the character class.
     */

    init?(rawValue: String) {
        switch rawValue {
        case "unicode": self = .unicode
        case "upper": self = .uppercase
        case "lower": self = .lowercase
        case "digits": self = .digits
        case "special": self = .special
        case "ascii-printable": self = .asciiPrintable
        default:
            // Custom sets are wrapped between square brackets
            guard rawValue.hasPrefix("[") && rawValue.hasSuffix("]") else { return nil }

            // Get the contents between the brackets
            let setStartIndex = rawValue.index(after: rawValue.startIndex)
            let setEndIndex = rawValue.index(before: rawValue.endIndex)

            // Create the character set
            let setContents = rawValue[setStartIndex ..< setEndIndex]
            self = .custom(String(setContents))
        }
    }

    /// The string describing the character set.
    var rawValue: String {
        switch self {
        case .unicode: return "unicode"
        case .uppercase: return "upper"
        case .lowercase: return "lower"
        case .digits: return "digits"
        case .special: return "special"
        case .asciiPrintable: return "ascii-printable"
        case .custom(let characterSet): return "[\(characterSet)]"
        }
    }

    // MARK: - Codable

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        guard let decodedSet = PasswordCharacterClass(rawValue: rawValue) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "'\(rawValue)' is not a valid character set.")
        }

        self = decodedSet
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    // MARK: - Standard Character Set

    /// The standard character set that represents the character class.
    var associatedCharacterSet: CharacterSet {
        switch self {
        case .unicode: return .unicode
        case .uppercase: return .asciiUppercaseLetters
        case .lowercase: return .asciiLowercaseLetters
        case .digits: return .decimalDigits
        case .asciiPrintable: return .asciiPrintableSet
        case .special: return CharacterSet.asciiStandardCharacters.inverted
        case .custom(let charactersString): return CharacterSet(charactersIn: charactersString)
        }
    }

}

