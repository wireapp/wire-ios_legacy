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

import SnapshotTesting
import XCTest
@testable import Wire

final class WireShareExtensionTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testThatShareExtensionViewController() throws {
        let sut = ShareExtensionViewController() ///TODO: can not s
        sut.view.backgroundColor = .white
        verify(matching: sut)
    }

    func testThatNotSignedInViewController() throws {
        let sut = NotSignedInViewController()
        sut.view.backgroundColor = .white
        verify(matching: sut)
    }

    func testThatAccountSelectionViewController() throws {
        let sut = AccountSelectionViewController(accounts: [], current: nil)
        sut.view.backgroundColor = .white
        verify(matching: sut, customSize: CGSize(width: 375, height: 667))
    }

    func testThatSendingProgressViewController() throws {
        let sut = SendingProgressViewController()
        sut.view.backgroundColor = .white
        verify(matching: sut)
    }

    func testThatConversationSelectionViewController() throws {
        let sut = ConversationSelectionViewController(conversations:[])
        sut.view.backgroundColor = .white
        verify(matching: sut, customSize: CGSize(width: 375, height: 667))
    }


    func testThatUnlockViewController() throws {
        let sut = UnlockViewController()
        sut.view.backgroundColor = .white
        verify(matching: sut)
    }

}
