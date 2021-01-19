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

// TODO: We may need to display a warning. Where should it go?
// TODO: Use the authentication type to determine what copy to display in the view.

extension AppLockModule {

    final class Presenter: PresenterInterface {

        var router: AppLockRouterPresenterInterface!
        var interactor: AppLockInteractorPresenterInterface!
        weak var view: AppLockViewPresenterInterface!

    }

}


// MARK: - API for interactor

extension AppLockModule.Presenter: AppLockPresenterInteractorInterface {

    func authenticationEvaluated(with result: AppLockModule.AuthenticationResult) {
        switch result {
        case .granted:
            interactor.openAppLock()

        case .denied:
            view.state = .locked

        case .needCustomPasscode:
            router.presentInputPasscodeModule(onGranted: interactor.openAppLock)

        case .unavailable:
            // TODO: Remove this case, it should never happen.
            fatalError("Not implemented")
        }
    }

}

// MARK: - API for view

extension AppLockModule.Presenter: AppLockPresenterViewInterface {

    func start() {
        if interactor.needsToCreateCustomPasscode {
            router.presentCreatePasscodeModule { [weak self] in
                self?.interactor.openAppLock()
            }
        } else {
            view.state = .authenticating
            interactor.evaluateAuthentication()
        }
    }

}
