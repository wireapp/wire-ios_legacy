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

enum AppLockModule: ModuleInterface {

    typealias Router = AppLockRouter
    typealias Interactor = AppLockInteractor
    typealias Presenter = AppLockPresenter
    typealias View = AppLockView

    static func build() -> View {
        let router = Router()
        let interactor = Interactor()
        let presenter = Presenter()
        let view = View()

        assemble(router: router, interactor: interactor, presenter: presenter, view: view)

        router.viewController = view

        return view
    }

}

// MARK: - Router / Presenter

protocol AppLockRouterPresenterInterface: RouterPresenterInterface {

    /// Router API exposed to the presenter.

}

// MARK: - Interactor / Presenter

protocol AppLockPresenterInteractorInterface: PresenterInteractorInterface {

    /// Presenter API exposed to the interactor.

}

protocol AppLockInteractorPresenterInterface: InteractorPresenterInterface {

    /// Interactor API exposed to the presenter.

}

// MARK: - View / Presenter

protocol AppLockViewPresenterInterface: ViewPresenterInterface {

    /// View API exposed to the presenter.

}

protocol AppLockPresenterViewInterface: PresenterViewInterface {

    /// Presenter API exposed to the view.

}
