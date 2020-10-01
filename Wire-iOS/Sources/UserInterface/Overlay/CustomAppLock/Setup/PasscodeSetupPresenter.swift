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

    private var passcodeValidationResult: PasscodeValidationResult?

    var isPasscodeValid: Bool {
        switch passcodeValidationResult {
        case .accepted:
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

    func passcodeValidated(result: PasscodeValidationResult) {
        passcodeValidationResult = result

        switch result {
        case .accepted:
            userInterface?.createButtonEnabled = true
            resetValidationLabels(errors: Set(PasscodeError.allCases), passed: true)
        case .error(let errorReasons):
            userInterface?.createButtonEnabled = false

            // reset: if the passcode is too short, set all other as not passed
            let passed: Bool = errorReasons != [.tooShort]

            resetValidationLabels(errors: Set(PasscodeError.allCases), passed: passed)
            resetValidationLabels(errors: errorReasons, passed: false)
        }
    }

}
