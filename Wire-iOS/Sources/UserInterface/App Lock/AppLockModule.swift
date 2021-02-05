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

    static func build(session: Session) -> View {
        let router = Router()
        let interactor = Interactor(session: session)
        let presenter = Presenter()
        let view = View()

        assemble(router: router, interactor: interactor, presenter: presenter, view: view)

        return view
    }

}

// MARK: - Router / Presenter

protocol AppLockRouterPresenterInterface: RouterPresenterInterface {

    func present(_ module: AppLockModule.Module)

}

// MARK: - Interactor / Presenter

protocol AppLockPresenterInteractorInterface: PresenterInteractorInterface {

    func handle(_ result: AppLockModule.Result)

}

protocol AppLockInteractorPresenterInterface: InteractorPresenterInterface {

    func execute(_ request: AppLockModule.Request)

}

// MARK: - View / Presenter

protocol AppLockViewPresenterInterface: ViewPresenterInterface {

    func refresh(with model: AppLockModule.ViewModel)

}

protocol AppLockPresenterViewInterface: PresenterViewInterface {

    func processEvent(_ event: AppLockModule.Event)

}

extension AppLockModule {

    enum Result: Equatable {

        case customPasscodeCreationNeeded(shouldInform: Bool)
        case readyForAuthentication(shouldInform: Bool)
        case authenticationDenied(AuthenticationType)
        case authenticationUnavailable
        case customPasscodeNeeded

    }

    enum Request: Equatable {

        case initiateAuthentication
        case evaluateAuthentication
        case openAppLock

    }

    enum Module: Equatable {

        case createPasscode(shouldInform: Bool)
        case inputPasscode
        case informUserOfConfigChange

    }

    enum Event: Equatable {

        case viewDidLoad
        case unlockButtonTapped
        case passcodeSetupCompleted
        case customPasscodeVerified
        case configChangeAcknowledged
    }

}
