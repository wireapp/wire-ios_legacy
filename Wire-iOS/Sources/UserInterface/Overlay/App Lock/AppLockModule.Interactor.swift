//
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
import LocalAuthentication
import WireDataModel

extension AppLockModule {

    final class Interactor: InteractorInterface {

        // MARK: - Properties

        weak var presenter: AppLockPresenterInteractorInterface!

        let session: Session

        // MARK: - Life cycle

        init(session: Session) {
            self.session = session
        }

        // MARK: - Methods

        var appLock: AppLockType {
            session.appLockController
        }

    }

}

// MARK: - API for presenter

extension AppLockModule.Interactor: AppLockInteractorPresenterInterface {

    func evaluateAuthentication() {
        appLock.evaluateAuthentication(scenario: .screenLock(requireBiometrics: false),
                                       description: "Unlock Wire",
                                       with: handleAuthenticationResult)
    }

    private func handleAuthenticationResult(_ result: AppLockModule.AuthenticationResult, context: LAContext) {
        DispatchQueue.main.async {
            if case .granted = result {
                try? self.session.unlockDatabase(with: context)
            }

            self.presenter.authenticationEvaluated(with: result)
        }
    }

}
