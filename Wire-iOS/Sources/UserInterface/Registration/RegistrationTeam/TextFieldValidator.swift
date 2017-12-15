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

class TextFieldValidator {

    enum ValidationError: Error, Equatable {
        case tooShort(kind: AccessoryTextField.Kind)
        case tooLong(kind: AccessoryTextField.Kind)
        case invalidEmail
        case none


        static func ==(lhs: ValidationError, rhs: ValidationError) -> Bool {
            switch (lhs, rhs) {
            case let (.tooShort(l), .tooShort(r)),
                 let (.tooLong(l), .tooLong(r)):
                return l == r
            case (.invalidEmail, .invalidEmail),
                 (.none, .none):
                return true
            default:
                return false
            }
        }
    }

    func validate(text: String?, kind: AccessoryTextField.Kind) -> TextFieldValidator.ValidationError {
        guard let text = text else {
            return .none
        }

        switch kind {
        case .email:
            if text.count > 254 {
                return .tooLong(kind: kind)
            } else if !text.isEmail {
                return .invalidEmail
            }
        case .password:
            if text.count > 120 {
                return .tooLong(kind: kind)
            } else if text.count < 8 {
                return .tooShort(kind: kind)
            }
        case .name:
            /// We should ignore leading/trailing whitespace when counting the number of characters in the string
            let stringToValidate = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if stringToValidate.count > 64 {
                return .tooLong(kind: kind)
            } else if stringToValidate.count < 2 {
                return .tooShort(kind: kind)
            }
        case .unknown:
            break
        }

        return .none

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
            case .password:
                return "password.guidance.tooshort".localized
            case .unknown:
                return "unknown.guidance.tooshort".localized
            }
        case .tooLong(kind: let kind):
            switch kind {
            case .name:
                return "name.guidance.toolong".localized
            case .email:
                return "email.guidance.toolong".localized
            case .password:
                return "password.guidance.toolong".localized
            case .unknown:
                return "unknown.guidance.toolong".localized
            }
        case .invalidEmail:
            return "email.guidance.invalid".localized
        case .none:
            return ""
        }
    }

}

// MARK: - Email validator

extension String {
    public var isEmail: Bool {
        guard !self.hasPrefix("mailto:") else { return false }

        guard let dataDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return false }

        let stringToMatch = self.trimmingCharacters(in: .whitespacesAndNewlines) // We should ignore leading/trailing whitespace
        let range = NSRange(location: 0, length: stringToMatch.characters.count)
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
