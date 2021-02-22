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
import WireDataModel
import WireSyncEngine

/// This module is responsible for displaying the app lock and requesting
/// authentication from the user.

enum AppLockModule: ModuleInterface {

    typealias Session = UserSessionAppLockInterface & UserSessionEncryptionAtRestInterface
    typealias PasscodePreference = AppLockPasscodePreference
    typealias AuthenticationResult = AppLockAuthenticationResult
    typealias Strings = L10n.Localizable.AppLockModule

    static func build(session: Session) -> View {
        let router = Router()
        let interactor = Interactor(session: session)
        let presenter = Presenter()
        let view = View()

        assemble(interactor: interactor, presenter: presenter, view: view, router: router)

        return view
    }

}

extension AppLockModule {

    enum Event: Equatable {

        case viewDidLoad
        case applicationWillEnterForeground
        case unlockButtonTapped
        case openDeviceSettingsButtonTapped
        case passcodeSetupCompleted
        case customPasscodeVerified
        case configChangeAcknowledged

    }

    enum Request: Equatable {

        case initiateAuthentication
        case evaluateAuthentication
        case openAppLock

    }

    enum Result: Equatable {

        case customPasscodeCreationNeeded(shouldInform: Bool)
        case readyForAuthentication(shouldInform: Bool)
        case authenticationDenied(AuthenticationType)
        case authenticationUnavailable
        case customPasscodeNeeded

    }

    enum Action: Equatable {

        case createPasscode(shouldInform: Bool)
        case inputPasscode
        case informUserOfConfigChange
        case openDeviceSettings

    }

}

// MARK: - Interactor

protocol AppLockInteractorPresenterInterface: InteractorPresenterInterface {

    func executeRequest(_ request: AppLockModule.Request)

}

// MARK: - Presenter

protocol AppLockPresenterInteractorInterface: PresenterInteractorInterface {

    func handleResult(_ result: AppLockModule.Result)

}

protocol AppLockPresenterViewInterface: PresenterViewInterface {

    func processEvent(_ event: AppLockModule.Event)

}

// MARK: - View

protocol AppLockViewPresenterInterface: ViewPresenterInterface {

    func refresh(withModel model: AppLockModule.ViewModel)

}

// MARK: - Router

protocol AppLockRouterPresenterInterface: RouterPresenterInterface {

    func performAction(_ action: AppLockModule.Action)

}
