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

    func handle(_ result: AppLockModule.Result) {
        switch result {
        case let .customPasscodeCreationNeeded(shouldInform):
            router.present(.createPasscode(shouldInform: shouldInform), then: openAppLock)

        case let .readyForAuthentication(shouldInform):
            let authenticate = {
                self.view.refresh(with: .authenticating)
                self.interactor.execute(.evaluateAuthentication)
            }

            guard shouldInform else {
                authenticate()
                return
            }

            router.present(.informUserOfConfigChange, then: authenticate)

        case .customPasscodeNeeded:
            view.refresh(with: .locked(.passcode))
            router.present(.inputPasscode, then: openAppLock)

        case .authenticationDenied:
            view.refresh(with: .locked(interactor.currentAuthenticationType))

        case .authenticationUnavailable:
            view.refresh(with: .locked(.unavailable))
        }
    }

    private func openAppLock() {
        interactor.execute(.openAppLock)
    }

}

// MARK: - API for view

extension AppLockModule.Presenter: AppLockPresenterViewInterface {

    func processEvent(_ event: AppLockModule.Event) {
        switch event {
        case .viewDidLoad:
            view.refresh(with: .locked(interactor.currentAuthenticationType))
            interactor.execute(.initiateAuthentication)

        case .unlockButtonTapped:
            interactor.execute(.initiateAuthentication)
        }
    }

}
