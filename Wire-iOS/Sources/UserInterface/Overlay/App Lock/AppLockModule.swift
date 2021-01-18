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


enum AppLockModule: ModuleInterface {

    typealias Session = UserSessionAppLockInterface & UserSessionEncryptionAtRestInterface
    typealias AuthenticationScenario = AppLockController.AuthenticationScenario
    typealias AuthenticationResult = AppLockController.AuthenticationResult

    static func build(session: Session) -> View {
        let router = Router()
        let interactor = Interactor(session: session)
        let presenter = Presenter()
        let view = View()

        assemble(router: router, interactor: interactor, presenter: presenter, view: view)

        router.viewController = view

        return view
    }

}

// This module is responsible for displaying the app lock and requesting
// authentication from the user. The app lock always begins in a locked
// state.

// MARK: - Router / Presenter

protocol AppLockRouterPresenterInterface: RouterPresenterInterface {

    /// Router API exposed to the presenter.

}

// MARK: - Interactor / Presenter

protocol AppLockPresenterInteractorInterface: PresenterInteractorInterface {

    func authenticationEvaluated(with result: AppLockModule.AuthenticationResult)

}

protocol AppLockInteractorPresenterInterface: InteractorPresenterInterface {

    func evaluateAuthentication()

}

// MARK: - View / Presenter

protocol AppLockViewPresenterInterface: ViewPresenterInterface {

    var state: AppLockModule.ViewState { get set }

}

protocol AppLockPresenterViewInterface: PresenterViewInterface {

    func start()

}
