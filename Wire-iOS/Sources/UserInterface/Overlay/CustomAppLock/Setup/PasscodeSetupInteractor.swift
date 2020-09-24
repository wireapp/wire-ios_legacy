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
import WireCommonComponents
import WireTransport

protocol PasscodeSetupInteractorInput: class {
    func validate(error: TextFieldValidator.ValidationError?)
    func storePasscode(passcode: String) throws
}

protocol PasscodeSetupInteractorOutput: class {
    func passcodeValidated(result: PasscodeValidationResult)
}

final class PasscodeSetupInteractor {
    weak var interactorOutput: PasscodeSetupInteractorOutput?

    private let passwordCharacterClasses: [PasswordCharacterClass] = [.uppercase,
                                                                      .lowercase,
                                                                      .special,
                                                                      .digits]
}

// MARK: - Interface
extension PasscodeSetupInteractor: PasscodeSetupInteractorInput {
    func storePasscode(passcode: String) throws {
        guard let data = passcode.data(using: .utf8) else { return }

        try Keychain.updateItem(PasscodeKeychainItem.passcode, value: data)
    }

    private func passcodeError(from missingCharacterClasses: Set<WireUtilities.PasswordCharacterClass>) -> Set<PasscodeError> {
        var errorReasons: Set<PasscodeError> = Set()
        passwordCharacterClasses.forEach {
            if missingCharacterClasses.contains($0) {
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

        return errorReasons
    }

    func validate(error: TextFieldValidator.ValidationError?) {
        guard let error = error else {
            interactorOutput?.passcodeValidated(result: .accepted)
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
                result = .error(passcodeError(from: passwordCharacterClass))
            default:
                result = .error([])
            }
        default:
            result = .error([])
        }

        interactorOutput?.passcodeValidated(result: result)
    }

}
