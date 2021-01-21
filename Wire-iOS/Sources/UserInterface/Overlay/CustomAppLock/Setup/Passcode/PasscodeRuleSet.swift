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
 * A set of passcode rules that can be used to check if a password is valid.
 */

public struct PasscodeRuleSet: Decodable {

    /// The minimum length of the passcode.
    public let minimumLength: UInt

    /// The maximum length of the passcode.
    public let maximumLength: UInt

    /// The allowed set of characters.
    public let allowedCharacters: [PasscodeCharacterClass]

    /// The character set that represents the union of all the characters in `allowedCharacters`.
    public let allowedCharacterSet: CharacterSet

    /// The required classes of characters.
    public let requiredCharacters: [PasscodeCharacterClass]

    /// The required set of characters.
    public let requiredCharacterSets: [PasscodeCharacterClass: CharacterSet]

    // MARK: - Initialization

    /**
     * Creates the rule set from its required values.
     * - parameter minimumLength: The minimum length of the passcode.
     * - parameter maximumLength: The maximum length of the passcode.
     * - parameter allowedCharacters: The characters that are allowed in the passcode.
     * - parameter requiredCharacters: The characters that are required in the passcode. Note that if these are
     * not included in `allowedCharacters`, they will be added to that set.
     */

    public init(minimumLength: UInt, maximumLength: UInt, allowedCharacters: [PasscodeCharacterClass], requiredCharacters: [PasscodeCharacterClass]) {
        self.minimumLength = minimumLength
        self.maximumLength = maximumLength

        // Parse the allowed and required characters
        var allowedCharacters = allowedCharacters
        var allowedCharacterSet = allowedCharacters.reduce(into: CharacterSet()) { $0.formUnion($1.associatedCharacterSet) }
        var requiredCharacterSets: [PasscodeCharacterClass: CharacterSet] = [:]

        for requiredClass in requiredCharacters {
            allowedCharacters.append(requiredClass)
            let characterSet = requiredClass.associatedCharacterSet
            allowedCharacterSet.formUnion(characterSet)
            requiredCharacterSets[requiredClass] = characterSet
        }

        self.allowedCharacters = allowedCharacters
        self.allowedCharacterSet = allowedCharacterSet
        self.requiredCharacters = requiredCharacters
        self.requiredCharacterSets = requiredCharacterSets
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case minimumLength = "new_password_minimum_length"
        case maximumLength = "new_password_maximum_length"
        case allowedCharacters = "new_password_allowed_characters"
        case requiredCharacters = "new_password_required_characters"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let minimumLength = try container.decode(UInt.self, forKey: .minimumLength)
        let maximumLength = try container.decode(UInt.self, forKey: .maximumLength)
        let allowedCharacters = try container.decode([PasscodeCharacterClass].self, forKey: .allowedCharacters)
        let requiredCharacters = try container.decode([PasscodeCharacterClass].self, forKey: .requiredCharacters)
        self.init(minimumLength: minimumLength, maximumLength: maximumLength, allowedCharacters: allowedCharacters, requiredCharacters: requiredCharacters)
    }

    // MARK: - Encoding

    /// Encodes the rules in the format used by the Apple keychain.
    public func encodeInKeychainFormat() -> String {
        let allowed = allowedCharacters.map({ "allowed: \($0.rawValue)" }).joined(separator: "; ")
        let required = requiredCharacters.map({ "required: \($0.rawValue)" }).joined(separator: "; ")
        return "minlength: \(minimumLength); maxlength: \(maximumLength); \(allowed); \(required);"
    }

    // MARK: - Validation

    /**
     * Verifies that the specified passcode conforms to this password rule set.
     * - parameter password: The password to validate.
     * - returns: The validation result. `valid` if the passcode is valid, or
     * the description of the error.
     */

    public func validatePasscode(_ passcode: String) -> PasscodeValidationResult {
        var violations: [PasscodeValidationResult.Violation] = []
        
        let length = passcode.count

        // Start by checking the length.
        if length < minimumLength {
            violations.append(.tooShort)
        }

        if length > maximumLength {
            violations.append(.tooLong)
        }

        // Check for allowed and requiredCharacters
        var matchedRequiredClasses: Set<PasscodeCharacterClass> = []
        let requiredClasses = Set(requiredCharacterSets.keys)

        for scalar in passcode.unicodeScalars {
            guard allowedCharacterSet.contains(scalar) else {
                violations.append(.disallowedCharacter(scalar))
                return .invalid(violations: violations)
            }

            for (requiredClass, requiredCharacters) in requiredCharacterSets where !matchedRequiredClasses.contains(requiredClass) {
                if requiredCharacters.contains(scalar) {
                    matchedRequiredClasses.insert(requiredClass)
                }
            }
        }

        // Check if all the character classes are matched.
        let missingRequiredClasses = requiredClasses.subtracting(matchedRequiredClasses)
        if  !missingRequiredClasses.isEmpty {
            violations.append(.missingRequiredClasses(missingRequiredClasses))
        }

        return violations.isEmpty
            ? .valid
            : .invalid(violations: violations)
    }

}

