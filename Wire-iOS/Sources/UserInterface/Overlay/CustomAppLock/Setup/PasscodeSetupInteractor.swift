
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
import WireUtilities

enum ErrorReason: CaseIterable {
    case tooShort
    case noLowercaseChar
    case noUppercaseChar
    case noNumber
    case noSpecialChar
    
    var message: String {
        switch self {
            
        case .tooShort:
            return "create_passcode.validation.too_short".localized
        case .noLowercaseChar:
            return "create_passcode.validation.no_lowercase_char".localized
        case .noUppercaseChar:
            return "create_passcode.validation.no_uppercase_char".localized
        case .noSpecialChar:
            return "create_passcode.validation.no_special_char".localized
        case .noNumber:
            return "create_passcode.validation.no_number".localized
        }
    }
    
    var descriptionWithInvalidIcon: NSAttributedString {
        
        //TODO paint code icon
        let attributedString = NSAttributedString(string: "❌" + message)
        
        return attributedString
    }
    
    //TODO paint code icon
    var descriptionWithPassedIcon: NSAttributedString {
        
        let attributedString: NSAttributedString = NSAttributedString(string: "✅" + message)
        
        return attributedString
    }
}

enum PasscodeValidationResult {
    case accepted
    case error(Set<ErrorReason>)
}

protocol PasscodeSetupInteractorInput: class {
    func validate(error: TextFieldValidator.ValidationError?)
}

protocol PasscodeSetupInteractorOutput: class {
    func passcodeValidated(result: PasscodeValidationResult)
}

final class PasscodeSetupInteractor {
    weak var output: PasscodeSetupInteractorOutput?
    
    private let passwordCharacterClasses: [PasswordCharacterClass] = [.uppercase,
                                                                      .lowercase,
                                                                      .special,
                                                                      .digits]
}

// MARK: - Interface
extension PasscodeSetupInteractor: PasscodeSetupInteractorInput {
    
    func validate(error: TextFieldValidator.ValidationError?) {
        guard let error = error else {
            output?.passcodeValidated(result: .accepted)
            return
        }
        
        let result: PasscodeValidationResult
        switch error {
        case .tooShort:
            result = .error([.tooShort])
        case .invalidPassword(let passwordValidationResult):
            switch passwordValidationResult {
            case .tooShort:
                result = .error([.tooShort])
            case .missingRequiredClasses(let passwordCharacterClass):
                var errorReasons: Set<ErrorReason> = Set()
                passwordCharacterClasses.forEach() {
                    if passwordCharacterClass.contains($0) {
                        switch $0 {
                        case .uppercase:
                            errorReasons.insert(.noUppercaseChar)
                        case .lowercase:
                            errorReasons.insert(.noLowercaseChar)
                        case .special:
                            errorReasons.insert(.noSpecialChar)
                        case .digits:
                            errorReasons.insert(.noNumber)
                        default:
                            break
                        }
                    }
                }
                    
                result = .error(errorReasons)
            default:
                result = .error([])
            }
        default:
            result = .error([])
        }
       
        output?.passcodeValidated(result: result)
    }
    
}
