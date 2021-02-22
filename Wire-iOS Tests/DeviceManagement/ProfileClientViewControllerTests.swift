//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

import XCTest
@testable import Wire

final class ProfileClientViewControllerTests: ZMSnapshotTestCase {

    var sut: ProfileClientViewController!
    var user: ZMUser!
    var client: UserClient!

    override func setUp() {
        super.setUp()
        user = ZMUser.insertNewObject(in: uiMOC)
        accentColor = .vividRed

        client = UserClient.insertNewObject(in: uiMOC)
        client.remoteIdentifier = "102030405060708090"
        client.user = user
        client.deviceClass = .tablet
    }

    override func tearDown() {
        sut = nil
        user = nil
        client = nil

        resetColorScheme()

        super.tearDown()
    }

    func verify() {
        sut = ProfileClientViewController(client: client)
        sut.spinner.stopAnimating()
        sut.spinner.isHidden = true
        sut.showBackButton = false

        verify(view: sut.view, tolerance: 0.1)
    }

    func testTestForLightTheme(){
        ColorScheme.default.variant = .light
        verify()
    }

    func testTestForDarkTheme(){
        ColorScheme.default.variant = .dark
        verify()
    }
}
