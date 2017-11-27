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
        case tooLong
        case invalidEmail
        case none

        var localizedDescription: String {
            switch self {
            case .tooShort(kind: let kind):
                switch kind {
                case .name:
                    return "name.guidance.tooshort".localized
                default:
                    return "TODO"
                }
            default:
                return "TODO" ///TODO:
            }
        }

        static func ==(lhs: ValidationError, rhs: ValidationError) -> Bool {
            switch (lhs, rhs) {
            case let (.tooShort(l), .tooShort(r)):
                return l == r
//            case (.tooLong, .tooLong):
//                return true
//            case (.invalidEmail, .invalidEmail):
//                return true
//            case (.none, .none):
//                return true
            default:
                return lhs == rhs
            }
        }
    }

    func textDidChange(text: String?, kind: AccessoryTextField.Kind) -> TextFieldValidator.ValidationError {
        guard let text = text else {
            return .none
        }

        switch kind {
        case .email:
            if text.count > 254 {
                return .tooLong
            }
            else if !text.isEmail {
                return .invalidEmail
            }
        case .password:
            if text.count > 120 {
                return .tooLong
            }
            else if text.count < 8 {
                return .tooShort(kind: kind)
            }
        case .name:
            if text.count > 64 {
                return .tooLong
            }
            else if text.count < 2 {
                return .tooShort(kind: kind)
            }
        case .unknown:
            break
        }

        return .none

    }
}

// MARK:- Email validator

extension String {
    public var isEmail: Bool {
        guard !self.hasPrefix("mailto:") else { return false }

        let dataDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(location: 0, length: self.characters.count)
        let firstMatch = dataDetector?.firstMatch(in: self, options: NSRegularExpression.MatchingOptions.reportCompletion, range: range)

        let numberOfMatches = dataDetector?.numberOfMatches(in: self, options: NSRegularExpression.MatchingOptions.reportCompletion, range: range)

        if firstMatch?.range.location == NSNotFound { return false }
        if firstMatch?.url?.scheme != "mailto" { return false }
        if firstMatch?.url?.absoluteString.hasSuffix(self) == false { return false }
        if numberOfMatches != 1 { return false }

        /// patch the NSDataDetector for its false-positive cases
        if self.contains("..") { return false }

        return true
    }
}
