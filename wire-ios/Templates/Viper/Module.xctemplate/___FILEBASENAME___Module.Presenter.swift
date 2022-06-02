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

extension ___VARIABLE_productName:identifier___Module {

    final class Presenter: PresenterInterface {

        // MARK: - Properties

        var interactor: ___VARIABLE_productName:identifier___InteractorPresenterInterface!
        weak var view: ___VARIABLE_productName:identifier___ViewPresenterInterface!
        var router: ___VARIABLE_productName:identifier___RouterPresenterInterface!

    }

}

// MARK: - Handle result

extension ___VARIABLE_productName:identifier___Module.Presenter: ___VARIABLE_productName:identifier___PresenterInteractorInterface {

    func handleResult(_ result: ___VARIABLE_productName:identifier___Module.Result) {
        switch result {

        }
    }

}

// MARK: - Process event

extension ___VARIABLE_productName:identifier___Module.Presenter: ___VARIABLE_productName:identifier___PresenterViewInterface {

    func processEvent(_ event: ___VARIABLE_productName:identifier___Module.Event) {
        switch event {
        case .viewDidLoad:
          break
        }
    }

}
