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
            view.refresh(with: .locked(interactor.currentAuthenticationType))

        case .needCustomPasscode:
            view.refresh(with: .locked(.passcode))
            router.presentInputPasscodeModule(onGranted: interactor.openAppLock)

        case .unavailable:
            view.refresh(with: .locked(.unavailable))
        }
    }

}

// MARK: - API for view

extension AppLockModule.Presenter: AppLockPresenterViewInterface {

    func processEvent(_ event: AppLockModule.Event) {
        switch event {
        case .viewDidLoad:
            view.refresh(with: .locked(interactor.currentAuthenticationType))
            requestAuthentication()
        case .unlockButtonTapped:
            requestAuthentication()
        }
    }

    private func requestAuthentication() {
        if interactor.needsToCreateCustomPasscode {
            router.presentCreatePasscodeModule(shouldInform: interactor.needsToInformUserOfConfigurationChange) {
                self.interactor.openAppLock()
            }
        } else {
            warnUserOfConfigurationChangeIfNeeded {
                self.view.refresh(with: .authenticating)
                self.interactor.evaluateAuthentication()
            }
        }
    }

    private func warnUserOfConfigurationChangeIfNeeded(then block: @escaping () -> Void) {
        guard interactor.needsToInformUserOfConfigurationChange else {
            block()
            return
        }

        router.presentWarningModule(then: block)
    }

}
