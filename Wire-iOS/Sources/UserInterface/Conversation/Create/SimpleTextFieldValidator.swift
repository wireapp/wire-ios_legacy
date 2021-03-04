////
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
import WireUtilities
import UIKit

protocol SimpleTextFieldValidatorDelegate: class {
    func textFieldValueChanged(_ value: String?)
    func textFieldValueSubmitted(_ value: String)
    func textFieldDidEndEditing()
    func textFieldDidBeginEditing()
}

final class SimpleTextFieldValidator: NSObject {

    weak var delegate: SimpleTextFieldValidatorDelegate?

    enum ValidationError {
        case empty
        case tooLong
    }

    func validate(text: String) -> SimpleTextFieldValidator.ValidationError? {
        let stringToValidate = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if stringToValidate.isEmpty {
            return .empty
        }

        var validatedString: Any? = stringToValidate as Any

        do {
            _ = try StringLengthValidator.validateStringValue(&validatedString,
                                                    minimumStringLength: 1,
                                                    maximumStringLength: 64,
                                                    maximumByteLength: 256)
        }
        catch let stringValidationError as NSError {

            switch stringValidationError.code {
            case Int(ZMManagedObjectValidationErrorCode.tooLong.rawValue):
                return .tooLong
            default: break
            }
        }

        return nil
    }
}

extension SimpleTextFieldValidator: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let oldValue = textField.text as NSString?
        let result = oldValue?.replacingCharacters(in: range, with: string) ?? ""
        if !result.isEmpty, self.validate(text: result) != nil {
            return false
        }
        delegate?.textFieldValueChanged(result)
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text else { return true }
        delegate?.textFieldValueSubmitted(text)
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.textFieldDidEndEditing()
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.textFieldDidBeginEditing()
    }

}

extension SimpleTextFieldValidator.ValidationError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .tooLong:
            return "conversation.create.guidance.toolong".localized
        case .empty:
            return "conversation.create.guidance.empty".localized
        }
    }
}
