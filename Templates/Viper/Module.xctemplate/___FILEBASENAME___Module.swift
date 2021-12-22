//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

enum ___FILEBASENAMEASIDENTIFIER___: ModuleInterface {

    static func build() -> View {
        let interactor = Interactor()
        let presenter = Presenter()
        let view = View()
        let router = Router()

        assemble(interactor: interactor, presenter: presenter, view: view, router: router)

        return view
    }

}

extension ___FILEBASENAMEASIDENTIFIER___ {

  enum Event: Equatable {

      case viewDidLoad

  }

  enum Request: Equatable {}

  enum Result: Equatable {}

  enum Action: Equatable {}

}

// MARK: - Interactor

protocol ___VARIABLE_productName:identifier___InteractorPresenterInterface: InteractorPresenterInterface {

    func executeRequest(_ request: ___FILEBASENAMEASIDENTIFIER___.Request)

}

// MARK: - Presenter

protocol ___VARIABLE_productName:identifier___PresenterInteractorInterface: PresenterInteractorInterface {

    func handleResult(_ result: ___FILEBASENAMEASIDENTIFIER___.Result)

}

protocol ___VARIABLE_productName:identifier___PresenterViewInterface: PresenterViewInterface {

    func processEvent(_ event: ___FILEBASENAMEASIDENTIFIER___.Event)

}

// MARK: - View

protocol ___VARIABLE_productName:identifier___ViewPresenterInterface: ViewPresenterInterface {

    func refresh(withModel model: ___FILEBASENAMEASIDENTIFIER___.ViewModel)

}

// MARK: - Router

protocol ___VARIABLE_productName:identifier___RouterPresenterInterface: RouterPresenterInterface {

    func performAction(_ action: ___FILEBASENAMEASIDENTIFIER___.Action)

}
