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

        // MARK: - Properties

        var router: AppLockRouterPresenterInterface!
        var interactor: AppLockInteractorPresenterInterface!
        weak var view: AppLockViewPresenterInterface!

    }

}


// MARK: - Handle result

extension AppLockModule.Presenter: AppLockPresenterInteractorInterface {

    func handle(result: AppLockModule.Result) {
        switch result {
        case let .customPasscodeCreationNeeded(shouldInform):
            router.perform(action: .createPasscode(shouldInform: shouldInform))

        case .readyForAuthentication(shouldInform: true):
            router.perform(action: .informUserOfConfigChange)

        case .readyForAuthentication:
            authenticate()

        case .customPasscodeNeeded:
            view.refresh(with: .locked(.passcode))
            router.perform(action: .inputPasscode)

        case let .authenticationDenied(authenticationType):
            view.refresh(with: .locked(authenticationType))

        case .authenticationUnavailable:
            view.refresh(with: .locked(.unavailable))
        }
    }

}

// MARK: - Process event

extension AppLockModule.Presenter: AppLockPresenterViewInterface {

    func process(event: AppLockModule.Event) {
        switch event {
        case .viewDidLoad, .unlockButtonTapped:
            interactor.execute(request: .initiateAuthentication)

        case .passcodeSetupCompleted, .customPasscodeVerified:
            interactor.execute(request: .openAppLock)

        case .configChangeAcknowledged:
            authenticate()
        }
    }

}

// MARK: - Helpers

extension AppLockModule.Presenter {

    private func authenticate() {
        view.refresh(with: .authenticating)
        interactor.execute(request: .evaluateAuthentication)
    }

}
