
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

enum PasscodeValidationResult {
    case accepted
    case error
}

protocol PasscodeSetupInteractorInput: class {
    func validate(error: TextFieldValidator.ValidationError?)
}

protocol PasscodeSetupInteractorOutput: class {
    func passcodeValidated(result: PasscodeValidationResult)
}

final class PasscodeSetupInteractor {
    weak var output: PasscodeSetupInteractorOutput?
}

// MARK: - Interface
extension PasscodeSetupInteractor: PasscodeSetupInteractorInput {
    func validate(error: TextFieldValidator.ValidationError?) {
        if error == nil {
            output?.passcodeValidated(result: .accepted)
        } else {
            ///TODO
            output?.passcodeValidated(result: .error)
        }
        
    }
    
}
