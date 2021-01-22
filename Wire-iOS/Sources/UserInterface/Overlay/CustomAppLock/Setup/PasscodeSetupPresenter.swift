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

final class PasscodeSetupPresenter {
    private weak var userInterface: PasscodeSetupUserInterface?
    private var interactorInput: PasscodeSetupInteractorInput

    private var passcodeValidationResult: PasswordValidationResult?
    private let passcodeCharacterClasses: [PasswordCharacterClass] = [.uppercase,
                                                                      .lowercase,
                                                                      .special,
                                                                      .digits]
    
    var isPasscodeValid: Bool {
        switch passcodeValidationResult {
        case .valid:
            return true
        default:
            return false
        }
    }

    convenience init(userInterface: PasscodeSetupUserInterface) {
        let interactor = PasscodeSetupInteractor()
        self.init(userInterface: userInterface, interactorInput: interactor)
        interactor.interactorOutput = self
    }

    init(userInterface: PasscodeSetupUserInterface,
         interactorInput: PasscodeSetupInteractorInput) {
        self.userInterface = userInterface
        self.interactorInput = interactorInput
    }

    func validate(error: TextFieldValidator.ValidationError?) {
        interactorInput.validate(error: error)
    }

    func storePasscode(passcode: String, callback: ResultHandler?) {
        do {
            try interactorInput.storePasscode(passcode: passcode)
            callback?(true)
        } catch {
            callback?(false)
        }
    }
}

// MARK: - InteractorOutput

extension PasscodeSetupPresenter: PasscodeSetupInteractorOutput {
    private func resetValidationLabels(errors: Set<PasscodeError>, passed: Bool) {
        errors.forEach { errorReason in
            userInterface?.setValidationLabelsState(errorReason: errorReason, passed: passed)
        }
    }

    func passcodeValidated(result: PasswordValidationResult) {
        passcodeValidationResult = result

        switch result {
        case .valid:
            userInterface?.createButtonEnabled = true
            resetValidationLabels(errors: Set(PasscodeError.allCases), passed: true)
        case .invalid(let violations):
            userInterface?.createButtonEnabled = false

            resetValidationLabels(errors: Set(PasscodeError.allCases), passed: true)
            resetValidationLabels(errors: passcodeError(from: violations), passed: false)
        }
    }
}

// MARK: - Helpers

extension PasscodeSetupPresenter {
    private func passcodeError(from violations: [PasswordValidationResult.Violation]) -> Set<PasscodeError> {
        var passcodeErrors: Set<PasscodeError> = Set()
        violations.forEach { (violation) in
            switch violation {
            case .tooShort:
                passcodeErrors.insert(.tooShort)
            case .missingRequiredClasses(let passwordCharacterClass):
                passcodeErrors = passcodeErrors.union(passcodeError(from: passwordCharacterClass))
            default:
                break
            }
        }
        return passcodeErrors
    }
    
    private func passcodeError(from missingCharacterClasses: Set<PasswordCharacterClass>) -> Set<PasscodeError> {
        var passcodeErrors: Set<PasscodeError> = Set()
        passcodeCharacterClasses.forEach {
            if missingCharacterClasses.contains($0) {
                switch $0 {
                case .uppercase:
                    passcodeErrors.insert(.noUppercaseChar)
                case .lowercase:
                    passcodeErrors.insert(.noLowercaseChar)
                case .special:
                    passcodeErrors.insert(.noSpecialChar)
                case .digits:
                    passcodeErrors.insert(.noNumber)
                default:
                    break
                }
            }
        }
        
        return passcodeErrors
    }
}
