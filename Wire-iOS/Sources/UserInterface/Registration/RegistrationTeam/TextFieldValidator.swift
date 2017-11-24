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

enum TextFieldType {
    case email
    case name
    case password
    case unknown
}

enum TextFieldValidationError: Error {
    case tooShort, tooLong, invalidEmail
}

protocol TextFieldValidatorDelegate: class {
    func validationErrorDidOccur(error: TextFieldValidationError?)
    func validationSucceed()
}

class TextFieldValidator {
    weak var delegate: TextFieldValidatorDelegate?

    func textDidChange(text: String?, textFieldType: TextFieldType){
        guard let text = text else {
            return
        }

        var isError = false

        switch textFieldType {
        case .email:
            if text.count > 254 {
                delegate?.validationErrorDidOccur(error:.tooLong)
                isError = true
            }
            else if !text.isEmail {
                delegate?.validationErrorDidOccur(error:.invalidEmail)
                isError = true
            }
        case .password:
            if text.count > 120 {
                delegate?.validationErrorDidOccur(error:.tooLong)
                isError = true
            }
            else if text.count < 8 {
                delegate?.validationErrorDidOccur(error:.tooShort)
                isError = true
            }
        case .name:
            if text.count > 64 {
                delegate?.validationErrorDidOccur(error:.tooLong)
                isError = true
            }
            else if text.count < 2 {
                delegate?.validationErrorDidOccur(error:.tooShort)
                isError = true
            }
        case .unknown:
            break
        }

        if !isError {
            delegate?.validationSucceed()
        }
    }
}

// MARK:- Email validator

extension String {
    public var isEmail: Bool {
        let dataDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let firstMatch = dataDetector?.firstMatch(in: self, options: NSRegularExpression.MatchingOptions.reportCompletion, range: NSRange(location: 0, length: self.characters.count))

        return (firstMatch?.range.location != NSNotFound &&
            firstMatch?.url?.scheme == "mailto" &&
            !self.hasPrefix("mailto:"))
    }
}
