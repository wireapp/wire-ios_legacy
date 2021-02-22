//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import WireUtilities
import UIKit

final class TextFieldValidator {

    var customValidator: ((String) -> ValidationError?)?

    enum ValidationError: Error, Equatable {
        case tooShort(kind: ValidatedTextField.Kind)
        case tooLong(kind: ValidatedTextField.Kind)
        case invalidEmail
        case invalidPhoneNumber
        case invalidPassword([PasswordValidationResult.Violation])
        case custom(String)
    }

    private func validatePasscode(text: String,
                                  kind: ValidatedTextField.Kind,
                                  isNew: Bool) -> TextFieldValidator.ValidationError? {
        if isNew {
            // If the user is registering, enforce the password rules
            let result = PasswordRuleSet.shared.validatePassword(text)
            switch result {
            case .valid:
                return nil
            case .invalid(let violations):
                return .invalidPassword(violations)
            }
        } else {
            // If the user is signing in, we do not require any format
            return text.isEmpty ? .tooShort(kind: kind) : nil
        }
    }

    func validate(text: String?, kind: ValidatedTextField.Kind) -> TextFieldValidator.ValidationError? {
        guard let text = text else {
            return nil
        }

        if let customError = customValidator?(text) {
            return customError
        }

        switch kind {
        case .email:
            if text.count > 254 {
                return .tooLong(kind: kind)
            } else if !text.isEmail {
                return .invalidEmail
            }

        case .password(let isNew):
            return validatePasscode(text: text, kind: kind, isNew: isNew)
        case .passcode(let isNew):
            return validatePasscode(text: text, kind: kind, isNew: isNew)
        case .name:
            /// We should ignore leading/trailing whitespace when counting the number of characters in the string
            let stringToValidate = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if stringToValidate.count > 64 {
                return .tooLong(kind: kind)
            } else if stringToValidate.count < 2 {
                return .tooShort(kind: kind)
            }
        case .phoneNumber, .unknown:
            // phone number is validated with the custom validator
            break
        }

        return .none

    }
}

extension TextFieldValidator {

    @available(iOS 12, *)
    var passwordRules: UITextInputPasswordRules {
        return UITextInputPasswordRules(descriptor: PasswordRuleSet.shared.encodeInKeychainFormat())
    }

}

extension TextFieldValidator.ValidationError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .tooShort(kind: let kind):
            switch kind {
            case .name:
                return "name.guidance.tooshort".localized
            case .email:
                return "email.guidance.tooshort".localized
            case .password, .passcode:
                return PasswordRuleSet.localizedErrorMessage
            case .unknown:
                return "unknown.guidance.tooshort".localized
            case .phoneNumber:
                return "phone.guidance.tooshort".localized
            }
        case .tooLong(kind: let kind):
            switch kind {
            case .name:
                return "name.guidance.toolong".localized
            case .email:
                return "email.guidance.toolong".localized
            case .password, .passcode:
                return "password.guidance.toolong".localized
            case .unknown:
                return "unknown.guidance.toolong".localized
            case .phoneNumber:
                return "phone.guidance.toolong".localized
            }
        case .invalidEmail:
            return "email.guidance.invalid".localized
        case .invalidPhoneNumber:
            return "phone.guidance.invalid".localized
        case .custom(let description):
            return description
        case .invalidPassword(let violations):
            return violations.contains(.tooLong)
                ? "password.guidance.toolong".localized
                : PasswordRuleSet.localizedErrorMessage
        }
    }

}

// MARK: - Email validator

extension String {
    public var isEmail: Bool {
        guard !self.hasPrefix("mailto:") else { return false }

        guard let dataDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return false }

        let stringToMatch = self.trimmingCharacters(in: .whitespacesAndNewlines) // We should ignore leading/trailing whitespace
        let range = NSRange(location: 0, length: stringToMatch.count)
        let firstMatch = dataDetector.firstMatch(in: stringToMatch, options: NSRegularExpression.MatchingOptions.reportCompletion, range: range)

        let numberOfMatches = dataDetector.numberOfMatches(in: stringToMatch, options: NSRegularExpression.MatchingOptions.reportCompletion, range: range)

        if firstMatch?.range.location == NSNotFound { return false }
        if firstMatch?.url?.scheme != "mailto" { return false }
        if firstMatch?.url?.absoluteString.hasSuffix(stringToMatch) == false { return false }
        if numberOfMatches != 1 { return false }

        /// patch the NSDataDetector for its false-positive cases
        if self.contains("..") { return false }

        return true
    }
}
