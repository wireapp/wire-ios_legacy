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

        var router: ___VARIABLE_productName:identifier___RouterPresenterInterface!
        var interactor: ___VARIABLE_productName:identifier___InteractorPresenterInterface!
        weak var view: ___VARIABLE_productName:identifier___ViewPresenterInterface!

    }

}

// MARK: - API for interactor

extension ___VARIABLE_productName:identifier___Module.Presenter: ___VARIABLE_productName:identifier___PresenterInteractorInterface { }

// MARK: - API for view

extension ___VARIABLE_productName:identifier___Module.Presenter: ___VARIABLE_productName:identifier___PresenterViewInterface { }
