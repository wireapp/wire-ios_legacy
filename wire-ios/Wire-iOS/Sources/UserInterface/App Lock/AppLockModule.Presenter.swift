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
import UIKit

extension AppLockModule {

    final class Presenter: PresenterInterface {

        // MARK: - Properties

        var interactor: AppLockInteractorPresenterInterface!
        weak var view: AppLockViewPresenterInterface!
        var router: AppLockRouterPresenterInterface!

    }

}

// MARK: - Handle result

extension AppLockModule.Presenter: AppLockPresenterInteractorInterface {

    func handleResult(_ result: AppLockModule.Result) {
        switch result {
        case let .customPasscodeCreationNeeded(shouldInform):
            router.performAction(.createPasscode(shouldInform: shouldInform))

        case .readyForAuthentication(shouldInform: true):
            router.performAction(.informUserOfConfigChange)

        case .readyForAuthentication:
            authenticate()

        case .customPasscodeNeeded:
            view.refresh(withModel: .locked(.passcode))
            router.performAction(.inputPasscode)

        case let .authenticationDenied(authenticationType):
            view.refresh(withModel: .locked(authenticationType))

        case .authenticationUnavailable:
            view.refresh(withModel: .locked(.unavailable))
        }
    }

}

// MARK: - Process event

extension AppLockModule.Presenter: AppLockPresenterViewInterface {

    func processEvent(_ event: AppLockModule.Event) {
        switch event {
        // In iOS 14, it was found that 'viewDidAppear' may be invoked even when the app is in the background. To prevent re-authentication when the app is in the background, there is the 'requireActiveApp' parameter.
        case .viewDidAppear, .unlockButtonTapped:
            interactor.executeRequest(.initiateAuthentication(requireActiveApp: true))

        case .applicationWillEnterForeground:
            interactor.executeRequest(.initiateAuthentication(requireActiveApp: false))

        case .passcodeSetupCompleted, .customPasscodeVerified:
            interactor.executeRequest(.openAppLock)

        case .configChangeAcknowledged:
            authenticate()

        case .openDeviceSettingsButtonTapped:
            router.performAction(.openDeviceSettings)
        }
    }

}

// MARK: - Helpers

extension AppLockModule.Presenter {

    private func authenticate() {
        view.refresh(withModel: .authenticating)
        interactor.executeRequest(.evaluateAuthentication)
    }

}
