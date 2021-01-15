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
import XCTest
@testable import Wire

final class ___FILEBASENAMEASIDENTIFIER___: XCTestCase {

    private var sut: ___VARIABLE_productName:identifier___Module.Interactor!
    private var presenter: ___VARIABLE_productName:identifier___Module.MockPresenter!

    override func setUp() {
        super.setUp()
        sut = ___VARIABLE_productName:identifier___Module.Interactor()
        presenter = ___VARIABLE_productName:identifier___Module.MockPresenter()

        sut.presenter = presenter
    }

    override func tearDown() {
        sut = nil
        presenter = nil
        super.tearDown()
    }

    // MARK: - Tests

}
