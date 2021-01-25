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

final class WipeDatabasePresenter {
    weak var userInterface: WipeDatabaseUserInterface?
    var interactorInput: WipeDatabaseInteractorInput?
    var wireframe: WipeDatabaseWireframe!

    private func displayWipeCompletionScreen() {
        wireframe.presentWipeCompletion(from: userInterface)
    }
    
    func confirmAlertCallback() -> RequestPasswordController.Callback {
        return { [weak self] confirmText in
            guard confirmText == "wipe_database.alert.confirm_input".localized else {
                return
            }
            
            self?.interactorInput?.deleteAccount()
            
            self?.displayWipeCompletionScreen()            
        }
    }
    
    func confirmAlertInputValidation() -> RequestPasswordController.InputValidation {
        return { confirmText in
            return confirmText == "wipe_database.alert.confirm_input".localized
        }
    }
}

// MARK: - InteractorOutput

extension WipeDatabasePresenter: WipeDatabaseInteractorOutput {
}
